import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscupapp2/my_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'globalclass.dart';

void _listenMethod() {
  const methodChannel = MethodChannel("alarm_channel");
  methodChannel.setMethodCallHandler((call) async {
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  const methodChannel = MethodChannel("alarm_channel");
  try {
    await methodChannel.invokeMethod("setAlarms");
    await methodChannel.invokeMethod("requestExactAlarmPermission");
  } catch (e) {
    debugPrint("Platform channel error: $e");
  }
  _listenMethod();
  runApp(const MyApp());
}
