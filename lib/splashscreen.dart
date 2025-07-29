import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'DebugmodeScreen.dart';
import 'dashboardscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const platformForDebug = MethodChannel('com.techwings.fmiscupapp2');

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      checkDeveloperMode(context);
    });

    syncOfflineLoginData();
  }

  static Future<void> checkDeveloperMode(BuildContext context) async {
    if (!Platform.isAndroid) {
      // ✅ Skip check on iOS
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
      return;
    }

    try {
      final bool isEnabled = await platformForDebug.invokeMethod(
        'isDeveloperModeEnabled',
      );
      if (isEnabled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DebugModeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on PlatformException catch (e) {
      print("Failed to check developer mode: ${e.message}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  Future<void> syncOfflineLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('offlineEmail');
    final String? password = prefs.getString('offlinePassword');
    if (email != null && password != null) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        const String url =
            'https://fcrupid.fmisc.up.gov.in/api/appuserapi/login?userid=user1@gmail.com&password=Alok';
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            if (jsonResponse['success'] == true) {
              await prefs.remove('offlineEmail');
              await prefs.remove('offlinePassword');
              print('✅ Offline data synced successfully');
            }
          }
        } catch (e) {
          print('Error syncing offline data: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFbddffa),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF66b5f8),
              Colors.white.withOpacity(0.0),
              const Color(0xFF4fabf6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/image/up.png', height: 150),
              const SizedBox(height: 5),
              Image.asset('assets/image/logo.png', height: 250),
              const SizedBox(height: 10),
              const Text(
                'Flood Management Information System Centre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Irrigation & Water Resources Department\nUttar Pradesh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Image.asset('assets/image/district.png', height: 300),
            ],
          ),
        ),
      ),
    );
  }
}
