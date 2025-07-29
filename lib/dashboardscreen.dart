import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fmiscupapp2/data_base/data_helper.dart';
import 'package:fmiscupapp2/globalclass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'entity/station_data.dart';
import 'loginscreen.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'main.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    checkDataAvailableInLocal();
    // scheduleAllNotifications();
  }

  void checkDataAvailableInLocal() async {
    List<StationData> listStationData = await DatabaseHelper().getUnsyncedData(
      "false",
    );
    if (listStationData.isNotEmpty) {
      if (await GlobalClass.checkInternet()) {
        savedDataOnServer(listStationData);
      }
    }
  }

  void savedDataOnServer(List<StationData> listStationData) async {
    var request;
    var uri;
    try {
      for (StationData stationData in listStationData) {
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
          // final id = jsonData['id'] ?? "";
          int update = await DatabaseHelper().updateStationSyncStatus();
          if (update > 0) {
            print("Data updated successfully in local database");
            print(message);
            // showDialogMethod(message, true);
          }
        } else {
          print("Server error: ${response.statusCode}");
          // showDialogMethod("Server error: ${response.statusCode}", false);
        }
      }
    } catch (e) {
      print("Error occurred: $e");
      // showDialogMethod("Error occurred:", false);
    }
  }

  // void showDialogMethod(String message, bool forWhat) {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (ctx) => AlertDialog(
  //           title: Text(forWhat ? "Success " : "Error"),
  //           content: Text(message),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(ctx).pop(),
  //               child: const Text("OK"),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  final ministers = [
    {
      'name': 'Yogi Adityanath',
      'position': 'Hon\'ble Chief Minister\nUttar Pradesh',
      'imagePath': 'assets/image/yogiji.jpg',
    },
    {
      'name': 'Shri Swatantra Dev Singh',
      'position': 'Hon\'ble Cabinet Minister\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/swatantra.jpg',
    },
    {
      'name': 'Shri Dinesh Khateek',
      'position': 'Hon\'ble Minister of State\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/dinesh.jpg',
    },
    {
      'name': 'Shri Ramkesh Nishad',
      'position': 'Hon\'ble Minister of State\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/ramkesh.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffE6F0FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xff1A237E),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered text
                Center(
                  child: Text(
                    'बाढ़ प्रहरी',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Left logo
                Positioned(
                  left: 10,
                  child: Row(
                    children: [
                      // IconButton(
                      //   icon: const Icon(Icons.arrow_back, color: Colors.white),
                      //   onPressed: () {
                      //     Navigator.pop(context); // Go back
                      //   },
                      // ),
                      // const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/image/logo.png'),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Blue Box with Hindi text
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF62c0fe), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: const Color(0xff1A237E), width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'FMISC फ्लड मोबाइल ऐप बाढ़ से संबंधित रियल-टाइम जानकारी, चेतावनियाँ और सुरक्षा युक्तियाँ प्रदान करता है। यह उपयोगकर्ताओं को बाढ़ प्रभावित क्षेत्रों के इंटरैक्टिव मानचित्र, आपातकालीन संपर्क विवरण और स्थानीय अधिकारियों को स्थिति रिपोर्ट करने की सुविधा प्रदान करता है। ',
                // यह ऐप नागरिकों, प्रशासन और राहतकर्मियों के लिए उपयोगी है',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign:
                    TextAlign
                        .justify, // Ensures the text stretches across the container
                //   textDirection: TextDirection.rtl, // Ensures Hindi text aligns properly
              ),
            ),
            SizedBox(height: 10),
            // Ministers Title
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff1A237E),
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                child: const Text(
                  "Hon'ble Ministers",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 10),
            // Minister Cards
            Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = constraints.maxWidth;

                  // Determine the number of columns and aspect ratio based on screen width
                  int crossAxisCount;
                  double aspectRatio;

                  if (screenWidth < 600) {
                    // Mobile
                    crossAxisCount = 2;
                    aspectRatio = 5.6 / 5;
                  } else if (screenWidth < 900) {
                    // Small Tablet
                    crossAxisCount = 3;
                    aspectRatio = 3.6 / 4.5;
                  } else {
                    // Large Tablet / Desktop
                    crossAxisCount = 4;
                    aspectRatio = 2.6 / 4;
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ministers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final minister = ministers[index];
                      final isWideImage = minister['name'] == 'Yogi Adityanath';
                      return MinisterCard(
                        name: minister['name']!,
                        position: minister['position']!,
                        imagePath: minister['imagePath']!,
                        isWideImage: isWideImage,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MinisterCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String position;
  final bool isWideImage;

  const MinisterCard({
    super.key,
    required this.name,
    required this.position,
    required this.imagePath,
    this.isWideImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.4,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF62c0fe), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Color(0xFF0D47A1), width: 1.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                imagePath,
                width: isWideImage ? 100 : 70,
                height: isWideImage ? 89 : 70,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.030,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              position,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.023,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
