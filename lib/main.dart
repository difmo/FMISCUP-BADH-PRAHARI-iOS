import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscupapp2/my_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'globalclass.dart';
import 'data_base/data_helper.dart'; // Your DatabaseHelper
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());

  // Initialize plugins safely after runApp
  _initializeApp();
}

// --------------------------
// Initialize Plugins / Channels
// --------------------------
Future<void> _initializeApp() async {
  await _requestNotificationPermission();
  await _setupPlatformChannels();
  await _initDatabase();
  await _initSharedPreferences();
}

// --------------------------
// Notification permission
// --------------------------
Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

// --------------------------
// Platform channels for alarm
// --------------------------
Future<void> _setupPlatformChannels() async {
  const methodChannel = MethodChannel("alarm_channel");

  // Request exact alarm permission
  try {
    await methodChannel.invokeMethod("requestExactAlarmPermission");
    await methodChannel.invokeMethod("setAlarms");
  } catch (e) {
    debugPrint("Platform channel error: $e");
  }

  // Listen for native calls
  methodChannel.setMethodCallHandler((call) async {
    if (call.method == "setAlarms") {
      GlobalClass.customToast("Alarm triggered from native!");
    }
  });
}

// --------------------------
// Database initialization
// --------------------------
Future<void> _initDatabase() async {
  try {
    await DatabaseHelper.instance;
  } catch (e) {
    debugPrint("Database init error: $e");
  }
}

// --------------------------
// SharedPreferences initialization
// --------------------------
Future<void> _initSharedPreferences() async {
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint("SharedPreferences init error: $e");
  }
}
