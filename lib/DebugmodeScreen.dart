import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugModeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: DebugAlertScreen());
  }
}

class DebugAlertScreen extends StatefulWidget {
  @override
  _DebugAlertScreenState createState() => _DebugAlertScreenState();
}

class _DebugAlertScreenState extends State<DebugAlertScreen> {
  static const platform = MethodChannel('com.techwings.fmiscupapp2');

  @override
  void initState() {
    super.initState();
  }

  void _openDeveloperSettings() async {
    try {
      await platform.invokeMethod('openDeveloperSettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 120),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'It looks like your phone has Developer Options enabled.',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'Hint: Please go to your phone settings and turn off Developer Options for better security.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openDeveloperSettings(); // Handle button press
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                // Button background color
                foregroundColor: Colors.white,
                // Text/icon color
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 8,
                // Shadow elevation
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                shadowColor: Colors.indigoAccent,
                // Shadow color
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text('Ok'),
            ),
          ],
        ),
      ),
    );
  }
}
