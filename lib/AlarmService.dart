import 'package:flutter/services.dart';

class AlarmService {
  static const platform = MethodChannel('alarm_channel');

  static Future<void> setAlarms() async {
    try {
      final result = await platform.invokeMethod('setAlarms');
      print('Set alarms: $result');
    } catch (e) {
      print('Error setting alarms: $e');
    }
  }

  static Future<void> cancelAlarms() async {
    try {
      final result = await platform.invokeMethod('cancelAlarms');
      print('Canceled alarms: $result');
    } catch (e) {
      print('Error canceling alarms: $e');
    }
  }
}
