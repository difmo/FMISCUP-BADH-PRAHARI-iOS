import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscupapp2/my_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'globalclass.dart';

const ALARM_CHANNEL = MethodChannel("alarm_channel");

void _listenMethod() {
  ALARM_CHANNEL.setMethodCallHandler((call) async {
    if (call.method == "setAlarms") {
      GlobalClass.customToast("Alarm triggered from native!");
    }
  });
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

Future<void> requestExactAlarmPermission() async {
  try {
    await ALARM_CHANNEL.invokeMethod("requestExactAlarmPermission");
  } catch (e) {
    debugPrint("Error requesting exact alarm permission: $e");
  }
}

Future<void> setAlarmsIfPermissionGranted() async {
  try {
    // This will only work if user has allowed exact alarms
    await ALARM_CHANNEL.invokeMethod("setAlarms");
  } catch (e) {
    debugPrint("Cannot set alarms yet: $e");
    GlobalClass.customToast(
      "Please allow exact alarms in app settings"
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestNotificationPermission();

  const methodChannel = MethodChannel("alarm_channel");

  try {
    // 1️⃣ Request exact alarm permission first
    await methodChannel.invokeMethod("requestExactAlarmPermission");

    // 2️⃣ Wait a little or prompt user to grant permission
    await Future.delayed(Duration(seconds: 2)); // optional, just to give time

    // 3️⃣ Then set alarms
    await methodChannel.invokeMethod("setAlarms");

  } catch (e) {
    debugPrint("Platform channel error: $e");
  }

  _listenMethod();

  runApp(const MyApp());
}
