import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:html/parser.dart' show parse;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboardscreen.dart';
import 'data_base/data_helper.dart';
import 'entity/station_data.dart';

class Seconddashboardscreen extends StatefulWidget {
  const Seconddashboardscreen({super.key});

  @override
  State<Seconddashboardscreen> createState() => _SeconddashboardscreenState();
}

class _SeconddashboardscreenState extends State<Seconddashboardscreen> {
  List<dynamic> _dataList = [];
  bool _isLoading = true;
  List<String> _timeSlots = [];
  List<int> _idList = [];
  String? _selectedTime;
  DateTime? _selectedDatedropdown;
  int? selectedId;
  final TextEditingController gaugeController = TextEditingController();
  final TextEditingController dischargeController = TextEditingController();
  final TextEditingController rainController = TextEditingController();
  double? maxFloodLevel;
  double? maxDischarge;
  String? _stationName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      loadStationName(),
      fetchTimeSlots(),
      loadSavedValues(),
      fetchValidationData(),
      fetchData(),
    ]);
  }

  Future<void> loadStationName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stationName = prefs.getString('stationName') ?? 'Unknown Station';
    });
    debugPrint('_stationName: $_stationName');
  }

  Future<void> fetchTimeSlots() async {
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/TimeSlot",
    );
    try {
      final response = await http.get(url);
      debugPrint("TimeSlot response: ${response.body}");
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] is List) {
          setState(() {
            _timeSlots = List<String>.from(jsonBody['data']);
            _selectedTime = null;
          });
        }
      }
    } catch (e) {
      debugPrint("TimeSlot fetch error: $e");
    }
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    String stationID = prefs.getString('stationID') ?? "1";
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/getunapproveddata?stationid=$stationID",
    );
    try {
      final response = await http.get(url);
      debugPrint("Status Code getunapproveddata: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'];
        setState(() {
          _dataList = data ?? [];
          _idList = data?.map<int>((item) => item['id'] as int).toList() ?? [];
          _isLoading = false;
        });
        debugPrint("Extracted IDs: $_idList");
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch data error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gaugeController.text = prefs.getString('gauge') ?? '';
      dischargeController.text = prefs.getString('discharge') ?? '';
      rainController.text = prefs.getString('rain') ?? '';
      _selectedTime = prefs.getString('selectedTime');
    });
  }

  Future<void> fetchValidationData() async {
    final prefs = await SharedPreferences.getInstance();
    String stationID = prefs.getString('stationID') ?? "1";
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/ValidateFData?stationid=$stationID",
    );
    try {
      final response = await http.get(url);
      debugPrint("ValidateFData response: ${response.body}");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("Validation Data: $body");
        final String dataString = body['data'] ?? '';
        final cleanedString = dataString.replaceAll(RegExp(r'[{} ]'), '');
        final parts = cleanedString.split(',');
        for (var part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            if (keyValue[0] == 'maxFloodLevel') {
              print("Max Flood Level: ${keyValue[1]}");
              maxFloodLevel = double.tryParse(keyValue[1]);
            } else if (keyValue[0] == 'maxDischarge') {
              maxDischarge = double.tryParse(keyValue[1]);
            }
          }
        }
        debugPrint(
          "Parsed maxFloodLevel: $maxFloodLevel, maxDischarge: $maxDischarge",
        );
      }
    } catch (e) {
      debugPrint("Validation fetch error: $e");
    }
  }

  Future<void> validateAndSubmit(BuildContext context) async {
    final double? gauge = double.tryParse(gaugeController.text);
    final double? discharge = double.tryParse(dischargeController.text);
    if (gauge == null || discharge == null) {
      _showMessage(context, "Please enter valid Gauge and Discharge values.");
      return;
    }
    if (maxFloodLevel != null && gauge > maxFloodLevel!) {
      _showMessage(context, "Gauge exceeds maxFloodLevel ($maxFloodLevel)");
      return;
    }
    if (maxDischarge != null && discharge > maxDischarge!) {
      _showMessage(context, "Discharge exceeds maxDischarge ($maxDischarge)");
      return;
    }
    await updateFloodData(context, selectedId == null);
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "अत्यंत महत्वपूर्ण सूचना",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "कृपया Submit करने से पहले सुनिश्चित कर लें।",
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  validateAndSubmit(context);
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  Future<void> updateFloodData(BuildContext context, bool isInsert) async {
    if (gaugeController.text.isEmpty ||
        dischargeController.text.isEmpty ||
        rainController.text.isEmpty ||
        _selectedTime == null ||
        _selectedDatedropdown == null) {
      _showDialog(context, "Error", "All fields are required.", false);
      return;
    }

    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDatedropdown!);
    final prefs = await SharedPreferences.getInstance();
    final stationId = prefs.getString('stationID') ?? "";
    final floodData = StationData(
      id: selectedId?.toString() ?? "",
      gauge: gaugeController.text,
      discharge: dischargeController.text,
      todayRain: rainController.text,
      dataDate: formattedDate,
      dataTime: _selectedTime!,
      stationID: stationId,
      isSync: "false",
    );

    await savedDataOnServer(context, floodData);
    if (context.mounted) {
      if (isInsert) {
        await DatabaseHelper().insertStationData(floodData);
      } else {
        await DatabaseHelper().updateStationData(floodData);
      }
    }
  }

  // Save data to server sdfsf
  Future<void> savedDataOnServer(
    BuildContext context,
    StationData stationData,
  ) async {
    setState(() {
      _isSubmitting = true;
      _isLoading = true;
    });

    final uri =
        stationData.id.isEmpty
            ? Uri.parse(
              "https://fcrupid.fmisc.up.gov.in/api/AppStationAPI/PostFloodData",
            )
            : Uri.parse(
              "https://fcrupid.fmisc.up.gov.in/api/AppStationAPI/UpdateFloodData",
            );

    try {
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['Gauge'] = stationData.gauge
            ..fields['Discharge'] = stationData.discharge
            ..fields['TodayRain'] = stationData.todayRain
            ..fields['DataDate'] = stationData.dataDate
            ..fields['DataTime'] = stationData.dataTime
            ..fields['StationID'] = stationData.stationID;
      if (stationData.id.isNotEmpty) {
        request.fields['ID'] = stationData.id;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("Status Code UpdateFloodData: ${response.statusCode}");
      debugPrint("Response Body UpdateFloodData: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final message = jsonData['message'] ?? "Update successful";
        clearInputs();
        await fetchData();

        _showDialog(context, "Success", message, true);
      } else {
        String errorMessage = "Failed to update flood data.";
        try {
          final jsonData = jsonDecode(response.body);
          if (jsonData['errors'] != null) {
            Map<String, dynamic> errors = jsonData['errors'];
            List<String> errorDetails = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorDetails.addAll(value.cast<String>());
              } else if (value is String) {
                errorDetails.add(value);
              }
            });
            errorMessage = errorDetails.join("\n");
          } else if (jsonData['message'] != null) {
            errorMessage = jsonData['message'];
          }
        } catch (e) {
          errorMessage = "Error parsing response: ${response.statusCode}";
        }
        if (context.mounted) {
          _showDialog(context, "Error", errorMessage, false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showDialog(context, "Error", "Error occurred: $e", false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDialog(
    BuildContext context,
    String title,
    String message,
    bool isSuccess,
  ) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Color(0xff1A237E),
            title: Text(title, style: TextStyle(color: Colors.white)),
            content: Text(message, style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (isSuccess) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }

  void clearInputs() {
    gaugeController.clear();
    dischargeController.clear();
    rainController.clear();
    setState(() {
      _selectedTime = null;
      _selectedDatedropdown = null;
      selectedId = null;
    });
  }

  @override
  void dispose() {
    gaugeController.dispose();
    dischargeController.dispose();
    rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff1A237E),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/image/logo.png'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "Station: $_stationName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.login, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Center(
            child: Text(
              'Add Flood Information',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: gaugeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Gauge (Downstream)',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: dischargeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Discharge',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: rainController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Rain',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        backgroundColor: Colors.white,
                        showDragHandle: true,
                        context: context,
                        isScrollControlled: true, // allows custom height
                        builder:
                            (context) => SizedBox(
                              height:
                                  MediaQuery.of(context).size.height *
                                  0.4, // 40% of screen
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Today'),
                                    onTap:
                                        () => Navigator.pop(context, 'today'),
                                  ),
                                  // ListTile(
                                  //   title: const Text('Yesterday'),
                                  //   onTap:
                                  //       () => Navigator.pop(context, 'yesterday'),
                                  // ),
                                ],
                              ),
                            ),
                      );

                      if (selected != null && context.mounted) {
                        setState(() {
                          _selectedDatedropdown =
                              selected == 'today'
                                  ? DateTime.now()
                                  : DateTime.now().subtract(
                                    const Duration(days: 1),
                                  );
                        });
                        await fetchTimeSlots();
                      }
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDatedropdown == null
                                ? 'Date'
                                : '${_selectedDatedropdown!.day}/${_selectedDatedropdown!.month}/${_selectedDatedropdown!.year}',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedTime,
                        hint: const Text(
                          'Time',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        items:
                            _timeSlots
                                .map(
                                  (time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(
                                      time,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTime = value;
                            });
                          }
                        },
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : () {
                          _showConfirmDialog(context);
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dataList.isEmpty
                    ? const Center(child: Text("No data available"))
                    : ListView.builder(
                      itemCount: _dataList.length,
                      itemBuilder: (context, index) {
                        final item = _dataList[index];
                        final screenWidth = MediaQuery.of(context).size.width;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade900,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1A237E),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(3),
                                    topRight: Radius.circular(3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Station: ${parseHtmlString(item['stationName'] ?? '')}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: screenWidth * 0.032,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedId = item['id'];
                                          gaugeController.text =
                                              item['gauge']?.toString() ?? '';
                                          dischargeController.text =
                                              item['discharge']?.toString() ??
                                              '';
                                          rainController.text =
                                              item['todayRain']?.toString() ??
                                              '';

                                          String? fullDateTime =
                                              item['dataTime'];
                                          if (fullDateTime != null) {
                                            try {
                                              DateTime parsedDate = DateFormat(
                                                'dd-MMM-yyyy hh:mm a',
                                              ).parse(fullDateTime);
                                              _selectedDatedropdown =
                                                  parsedDate;

                                              final extractedTime = DateFormat(
                                                'hh:mm a',
                                              ).format(parsedDate);
                                              _selectedTime =
                                                  _timeSlots.contains(
                                                        extractedTime,
                                                      )
                                                      ? extractedTime
                                                      : null;
                                            } catch (e) {
                                              debugPrint(
                                                "Date parse error: $e",
                                              );
                                            }
                                          }
                                        });
                                      },

                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Gauge: ${item['gauge'] ?? 'N/A'}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Discharge: ${item['discharge'] ?? 'N/A'}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rain: ${item['todayRain'] ?? 'N/A'}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Date & Time: ${item['dataTime'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
