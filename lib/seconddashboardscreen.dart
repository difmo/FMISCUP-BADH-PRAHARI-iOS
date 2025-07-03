import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fmiscupapp2/globalclass.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:html/parser.dart' show parse;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboardscreen.dart';
import 'data_base/data_helper.dart';
import 'entity/station_data.dart';
import 'loginscreen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Seconddashboardscreen(),
    ),
  );
}

class Seconddashboardscreen extends StatefulWidget {
  const Seconddashboardscreen({super.key});

  @override
  State<Seconddashboardscreen> createState() => _SeconddashboardscreenState();
}

class _SeconddashboardscreenState extends State<Seconddashboardscreen> {
  List<dynamic> _dataList = [];
  bool _isLoading = true;
  List<String> _timeSlots = [];
  List<int> _idList = []; // To hold the list of IDs
  String? _selectedTime; // already a string
  DateTime? _selectedDate;
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
    fetchData();
    fetchTimeSlots();
    loadSavedValues();
    loadStationName();
    fetchValidationData();
  }


  Future<void> loadStationName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stationName = prefs.getString('stationName') ?? 'Unknown Station';
    });
    print('_stationName : $_stationName');
  }
  Future<void> fetchTimeSlots() async {
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/TimeSlot",
    );
    try {
      final response = await http.get(url);
      print("TimeSlot response: ${response.body}");
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] is List) {
          setState(() {
            _timeSlots = List<String>.from(jsonBody['data']);
            _selectedTime = null; // Reset on new fetch
          });
        }
      }
    } catch (e) {
      print("TimeSlot fetch error: $e");
    }
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    String _stationID = await prefs.getString('stationID') ?? "1";
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/getunapproveddata?stationid=$_stationID",
    );
    try {
      final response = await http.get(url);
      print("Status Code getunapproveddata: ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final data = jsonBody['data'];
        setState(() {
          _dataList.clear();
          _dataList = data;
          _idList =
              data
                  .map<int>((item) => item['id'] as int)
                  .toList(); // extract IDs
          _isLoading = false;
        });

        print("Extracted IDs: $_idList"); // optional debug print
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateFloodDataupdateOld(BuildContext context) async {
    setState(() {
      _isSubmitting = true;
      _isLoading = true; // Show CircularProgressIndicator
    });
    final uri = Uri.parse(
      'https://fcrupid.fmisc.up.gov.in/api/AppStationAPI/UpdateFloodData',
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('gauge', gaugeController.text);
    prefs.setString('discharge', dischargeController.text);
    prefs.setString('rain', rainController.text);
    prefs.setString('selectedTime', _selectedTime!);
    String? _stationID = prefs.getString('stationID') ?? "";
    final formattedDateForRequest = _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : '';
    var request = http.MultipartRequest('POST', uri)
          ..fields['ID'] = selectedId.toString() // Convert int to String
          ..fields['Gauge'] = gaugeController.text
          ..fields['Discharge'] = dischargeController.text
          ..fields['TodayRain'] = rainController.text
          ..fields['DataDate'] = formattedDateForRequest
          ..fields['DataTime'] = _selectedTime!
          ..fields['StationID'] = _stationID; // StationID is already a string
    print('objectid : $selectedId');
    print('DataDate : $formattedDateForRequest');
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("Status Code UpdateFloodData: ${response.statusCode}");
      print("Response Body UpdateFloodData: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final message = jsonData['message'] ?? 'No message';
        // Clear saved values in SharedPreferences if the response is successful
        prefs.remove('gauge');
        prefs.remove('discharge');
        prefs.remove('rain');
        prefs.remove('selectedTime');
        // ✅ Clear text fields and time after successful update
        gaugeController.clear();
        dischargeController.clear();
        rainController.clear();
        _selectedTime = null;
        await fetchData();
        // Show dialog with response message
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Response"),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Error"),
                content: Text(
                  "Failed to update flood data. Status code: ${response.statusCode}",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Exception"),
              content: Text("Error occurred: $e"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
        _isLoading = false; // Done loading
      });
    }
  }

  Future<void> updateFloodDataupdate(BuildContext context, bool forWhat) async {
    if (gaugeController.text.isEmpty ||
        dischargeController.text.isEmpty ||
        rainController.text.isEmpty ||
        _selectedTime == null ||
        _selectedDatedropdown == null) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Validation Error"),
              content: const Text("All fields are required."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
      return;
    }
    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDatedropdown!);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stationId = prefs.getString('stationID') ?? "";
    String ID = "";
    if (selectedId != null) {
      ID = selectedId.toString();
    }
    final floodData = StationData(
      id: ID,
      gauge: gaugeController.text,
      discharge: dischargeController.text,
      todayRain: rainController.text,
      dataDate: formattedDate,
      dataTime: _selectedTime!,
      stationID: stationId,
      isSync: "false",
    );
    if (await GlobalClass.checkInternet()) {
      savedDataOnServer(floodData);
    } else {
      int insertData = -1;
      int updateData = -1;
      if (forWhat) {
        insertData = await DatabaseHelper().insertStationData(floodData);
      } else {
        updateData = await DatabaseHelper().updateStationData(floodData);
      }
      if (insertData > 0) {
        showDialogMethod("Data Saved Successfully", true);
      }
      if (updateData > 0) {
        showDialogMethod("Data Update Successfully", true);
      }
    }
  }

  // Auto-fill text fields with saved values
  Future<void> loadSavedValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGauge = prefs.getString('gauge');
    String? savedDischarge = prefs.getString('discharge');
    String? savedRain = prefs.getString('rain');
    String? savedTime = prefs.getString('selectedTime');
    // Auto-fill text fields if values are available
    if (savedGauge != null) {
      gaugeController.text = savedGauge;
    }
    if (savedDischarge != null) {
      dischargeController.text = savedDischarge;
    }
    if (savedRain != null) {
      rainController.text = savedRain;
    }
    if (savedTime != null) {
      _selectedTime = savedTime;
    }
  }

  Future<void> fetchValidationData() async {
    final prefs = await SharedPreferences.getInstance();
    String _stationID = await prefs.getString('stationID') ?? "1";
    final url = Uri.parse(
      "https://fcrupid.fmisc.up.gov.in/api/appstationapi/ValidateFData?stationid=$_stationID",
    );
    try {
      final response = await http.get(url);
      print("ValidateFData response: ${response.body}");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final String dataString = body['data'];
        final cleanedString = dataString
            .replaceAll('{', ' ')
            .replaceAll('}', '')
            .replaceAll(' ', '');
        final parts = cleanedString.split(',');
        for (var part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            if (keyValue[0] == 'maxFloodLevel') {
              maxFloodLevel = double.tryParse(keyValue[1]);
            } else if (keyValue[0] == 'maxDischarge') {
              maxDischarge = double.tryParse(keyValue[1]);
            }
          }
        }
        print(
          "Parsed maxFloodLevel: $maxFloodLevel, maxDischarge: $maxDischarge",
        );
      }
    } catch (e) {
      print("Validation fetch error: $e");
    }
  }

  void validateAndSubmit() {
    final double? gauge = double.tryParse(gaugeController.text);
    final double? discharge = double.tryParse(dischargeController.text);
    if (gauge == null || discharge == null) {
      showMessage("Please enter valid Gauge and Discharge values.");
      return;
    }
    if (maxFloodLevel != null && gauge > maxFloodLevel!) {
      showMessage("Gauge exceeds maxFloodLevel ($maxFloodLevel)");
      return;
    }
    if (maxDischarge != null && discharge > maxDischarge!) {
      showMessage("Discharge exceeds maxDischarge ($maxDischarge)");
      return;
    }
    showMessage("Flood data is valid. Proceed to submit.");
    // TODO: Add API submission logic here.
  }
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
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
            // Use Navigator.pop with a result flag to indicate back action
            Navigator.pop(context, true); // You can pass true or any flag
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
                  style: TextStyle(
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
          // PreferredSize(
          //   preferredSize: const Size.fromHeight(60),
          //   child: AppBar(
          //     backgroundColor: Color(0xff1A237E),
          //     automaticallyImplyLeading: false, // We'll manually add the back icon
          //     leading: IconButton(
          //       icon: const Icon(Icons.arrow_back, color: Colors.white),
          //       onPressed: () {
          //         Navigator.pop(context); // Navigate back
          //       },
          //     ),
          //     flexibleSpace: Padding(
          //       padding: const EdgeInsets.only(
          //         top: 50,
          //         left: 16,
          //         right: 16,
          //       ),
          //       child: Row(
          //         children: [
          //           const SizedBox(width: 48), // To offset the CircleAvatar after leading icon
          //           const CircleAvatar(
          //             radius: 20,
          //             backgroundImage: AssetImage('assets/image/logo.png'),
          //             backgroundColor: Colors.white,
          //           ),
          //           const SizedBox(width: 40),
          //           const Text(
          //             'Station',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 20,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           const SizedBox(width: 6),
          //           const Text(
          //             'भीमगौड़ा',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 20,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           const Spacer(),
          //           IconButton(
          //             icon: const Icon(Icons.login, color: Colors.white),
          //             onPressed: () {
          //               Navigator.push(
          //                 context,
          //                 MaterialPageRoute(builder: (context) => const DashboardScreen()),
          //               );
          //             },
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
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
                hintText: 'Gauge(Downstream)',
                border: OutlineInputBorder(),
                isDense: true, // Reduces vertical height
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ), // Adjust as needed
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
                isDense: true, // Reduces vertical height
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ), // Adjust as needed
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
                isDense: true, // Reduces vertical height
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ), // Adjust as needed
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Date Field
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Show a simple bottom sheet or dialog to select Today or Yesterday
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Today'),
                                onTap: () => Navigator.pop(context, 'today'),
                              ),
                              ListTile(
                                title: const Text('Yesterday'),
                                onTap:
                                    () => Navigator.pop(context, 'yesterday'),
                              ),
                            ],
                          );
                        },
                      );
                      if (selected != null) {
                        setState(() {
                          _selectedDatedropdown =
                              selected == 'today'
                                  ? DateTime.now()
                                  : DateTime.now().subtract(
                                    const Duration(days: 1),
                                  );
                        });
                        await fetchTimeSlots(); // Call API after selection
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
                            style: TextStyle(fontSize: 15),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Time Field with border
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTime = value;
                          });
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
                          if (selectedId != null) {
                            print('selectedId : $selectedId');
                            updateFloodDataupdate(context, false);
                          } else {
                            updateFloodDataupdate(context, true);
                          }
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
          //   const SizedBox(height: 10),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
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
                              // Top blue header with station name and edit icon inside
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
                                        "Station: ${parseHtmlString(item['stationName'])}",
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
                                              item['gauge'].toString();
                                          dischargeController.text =
                                              item['discharge'].toString();
                                          rainController.text =
                                              item['todayRain'].toString();
                                          String? fullDateTime =
                                              item['dataTime'];
                                          String? extractedTime;
                                          if (fullDateTime != null &&
                                              fullDateTime.contains(' ')) {
                                            List<String> parts = fullDateTime
                                                .split(' ');
                                            if (parts.length >= 3) {
                                              extractedTime =
                                                  '${parts[1]} ${parts[2]}';
                                              _selectedTime =
                                                  _timeSlots.contains(
                                                        extractedTime,
                                                      )
                                                      ? extractedTime
                                                      : null;
                                            }
                                            try {
                                              final datePart = parts[0];
                                              final date = DateFormat(
                                                "dd-MMM-yyyy",
                                              ).parse(datePart);
                                              _selectedDate = date;
                                            } catch (e) {
                                              print("Date parsing error: $e");
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
                                      "Gauge: ${item['gauge']}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Discharge: ${item['discharge']}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rain: ${item['todayRain']}",
                                      style: const TextStyle(height: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Date & Time: ${item['dataTime']}",
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

  void savedDataOnServer(StationData stationData) async {
    setState(() {
      _isSubmitting = true;
      _isLoading = true;
    });
    var request;
    final uri;
    try {
      if ((stationData.id).isEmpty) {
        uri = Uri.parse(
          "https://fcrupid.fmisc.up.gov.in/api/AppStationAPI/PostFloodData",
        );
        request =
            http.MultipartRequest('POST', uri)
              ..fields['Gauge'] = stationData.gauge
              ..fields['Discharge'] = stationData.discharge
              ..fields['TodayRain'] = stationData.todayRain
              ..fields['DataDate'] = stationData.dataDate
              ..fields['DataTime'] = stationData.dataTime
              ..fields['StationID'] = stationData.stationID;
      } else {
        uri = Uri.parse(
          "https://fcrupid.fmisc.up.gov.in/api/AppStationAPI/UpdateFloodData",
        );
        request =
            http.MultipartRequest('POST', uri)
              ..fields['ID'] = stationData.id
              ..fields['Gauge'] = stationData.gauge
              ..fields['Discharge'] = stationData.discharge
              ..fields['TodayRain'] = stationData.todayRain
              ..fields['DataDate'] = stationData.dataDate
              ..fields['DataTime'] = stationData.dataTime
              ..fields['StationID'] = stationData.stationID;
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("Status Code UpdateFloodData: ${response.statusCode}");
      print("Response Body UpdateFloodData: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final message = jsonData['message'] ?? "Update successful";
        clearInputs();
        fetchData();
        showDialogMethod(message, true);
      } else {
        showDialogMethod("Server error: ${response.statusCode}", false);
      }
    } catch (e) {
      showDialogMethod("Error occurred:", false);
    } finally {
      setState(() {
        _isSubmitting = false;
        _isLoading = false;
      });
    }
  }

  void showDialogMethod(String message, bool forWhat) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(forWhat ? "Success" : "Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void clearInputs() {
    gaugeController.clear();
    dischargeController.clear();
    rainController.clear();

    setState(() {
      _selectedTime = null;
      _selectedDatedropdown = null;
    });
  }
}
