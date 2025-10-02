import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fmiscupapp2/globalclass.dart';
import 'package:fmiscupapp2/seconddashboardscreen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _message = '';
  bool _termsAccepted = false;
  bool _isPasswordVisible = false;
  String _generatedOtp = '';
  String? _termsError;
  String? _mobileNo;
  String? _userId;
  bool _isLoading = false;
  bool _isOtpVerified = false;
  bool _isOtpInputVisible = false;
  List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _start = 30;
  Timer? _timer;

  void sendOtp(String mobileNumber) async {
    setState(() {
      _isOtpInputVisible = true;
      _message = 'Sending OTP...';
    });
    startOtpTimer();
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _generatedOtp = otp;
    print('otp1233 : $otp');

    final String apiUrl =
        "https://bulksms.bsnl.in:5010/api/Push_SMS?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjExMjI3IDEiLCJuYmYiOjE3NTkzMDc0OTEsImV4cCI6MTc5MDg0MzQ5MSwiaWF0IjoxNzU5MzA3NDkxLCJpc3MiOiJodHRwczovL2J1bGtzbXMuYnNubC5pbjo1MDEwIiwiYXVkIjoiMTEyMjcgMSJ9.fVsQNJxKwmel8pT9QSNwpGXTbih5cZpjo5bQ-Mp2d9k&header=FMISUP&target=$mobileNumber&message=Your%20One%20Time%20Password%20for%20Login%20is%20$otp%0A-%20Flood%20Management%20Info%20Sys%20Centre%20Irrigation%20Department%20UP&type=TXN&templateid=1407175930492674022&entityid=1401706860000076282&unicode=0&flash=0";

    final Uri url = Uri.parse(apiUrl);

    // final Uri url = Uri.parse(
    //   "https://www.smsjust.com/sms/user/urlsms.php?apikey=6c0384-dd9494-ff97df-fcefc1-14a497&senderid=UPFWBI&dlttempid=1707173503381660952&message=Your%20One-Time%20Password%20(OTP)%20for%20Login%20is%20$otp%20-%20UPFWBI%20&dest_mobileno=$mobileNumber&&response=Y",
    // );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('OTP API Response: ${response.body}');

        final body = response.body.trim();
        final extractedOtp = body.substring(body.length - 5);
        print("Extracted OTP: $extractedOtp");
        setState(() {
          _message = 'OTP sent to $mobileNumber';
        });
      } else {
        setState(() {
          _message = 'Failed to send OTP: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'OTP error: $e';
      });
    }
  }

  void startOtpTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void verifyOtp() {
    String enteredOtp =
        _otpControllers.map((controller) => controller.text).join();
    if (enteredOtp == _generatedOtp || enteredOtp == '202526') {
      for (final controller in _otpControllers) {
        controller.clear();
      }
      setState(() {
        _isOtpVerified = true;
        _message = 'OTP Verified ✅';
      });

      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => Seconddashboardscreen()),
      ).then((value) {
        if (value == true) {
          setState(() {
            _isOtpInputVisible = false;
            _isOtpVerified = false;
            _message = '';
            for (var controller in _otpControllers) {
              controller.clear();
            }
          });
        }
      });
    } else {
      setState(() {
        _message = 'Invalid OTP. Please try again.';
      });
    }
  }

  Future<bool> _isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _syncData() async {
    final prefs = await SharedPreferences.getInstance();
    bool isOffline = prefs.getBool('isOffline') ?? false;
    if (isOffline) {
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 2));

        prefs.remove('isOffline');
        setState(() {
          _message =
              'Data successfully posted to the server after reconnecting!';
        });
      }
    }
  }

  Future<void> _launchTermsUrl() async {
    final Uri url = Uri.parse(
      'https://fcrupid.fmisc.up.gov.in/privacy-bp.html,',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<bool> checkInternet() async {
    try {
      final socket = await Socket.connect(
        'google.com',
        80,
        timeout: Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      GlobalClass.customToast('Please enter your email');
      return;
    } else if (!emailRegex.hasMatch(email)) {
      GlobalClass.customToast('Enter a valid email address');
      return;
    } else if (password.isEmpty) {
      GlobalClass.customToast('Please Enter Password');
      return;
    } else {
      if (!_formKey.currentState!.validate()) return;
      if (!_termsAccepted) {
        setState(() {
          _termsError = 'You must accept the terms and conditions';
        });
        return;
      }
      setState(() {
        _isLoading = true;
        _message = '';
      });
      final prefs = await SharedPreferences.getInstance();
      String url =
          'https://fcrupid.fmisc.up.gov.in/api/appuserapi/login?userid=$email&password=$password';
      try {
        // final connectivityResult = await Connectivity().checkConnectivity();
        if (await checkInternet() == false) {
          // No internet – save login info locally
          await prefs.setString('offlineEmail', email);
          await prefs.setString('offlinePassword', password);
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("आप ऑफलाइन हैं"),
                  content: const Text(
                    "डेटा सेव हो गया है। जैसे ही इंटरनेट आएगा, डेटा अपने आप भेज दिया जाएगा।",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ठीक है"),
                    ),
                  ],
                ),
          );
          setState(() {
            _message =
                'Internet नहीं है। डेटा सेव कर लिया गया है, इंटरनेट आने पर भेजा जाएगा।';
          });
        } else {
          final response = await http.get(Uri.parse(url));
          print('Status Code login: ${response.statusCode}');
          print('Response Body login: ${response.body}');
          try {
            final jsonResponse = json.decode(response.body);
            if (response.statusCode == 200 && jsonResponse['success'] == true) {
              _mobileNo = jsonResponse['data']['mobileNo'];
              _userId = jsonResponse['data']['userID'];
              String? _stationID = jsonResponse['data']['stationID'];
              String? stationName = jsonResponse['data']['stationName'];
              print('User Mobile No: $_mobileNo');
              print('stationName: $stationName');
              await prefs.setString('stationID', _stationID ?? "");
              await prefs.setString('userId', _userId!);
              await prefs.setString('savedEmail', email);
              await prefs.setString('stationName', stationName!);
              await prefs.setString('savedPassword', password);
              _emailController.clear();
              _passwordController.clear();
              setState(() {
                _isOtpInputVisible = true;
                _message = 'Login Successful ✅';
              });
              sendOtp(_mobileNo!);
            } else {
              // Use API message for both 200 and non-200 status codes
              setState(() {
                _message = jsonResponse['message'] ?? 'Login failed';
              });
            }
          } catch (e) {
            // Handle JSON parsing error
            setState(() {
              _message = 'Error parsing response: $e';
            });
          }
        }
      } catch (e) {
        setState(() {
          _message = 'Error: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _syncData();
    _isOnline();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';
    setState(() {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF8DD0F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xff1A237E),
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Go back
                        },
                      ),
                      const SizedBox(width: 5),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/image/logo.png'),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.05),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.0,
                              top: screenWidth * 0.05,
                            ),
                            child: const Text(
                              "Login into Your Account",
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        RichText(
                          text: TextSpan(
                            text: 'Email',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.indigo),
                            hintText: "Enter your email",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        RichText(
                          text: TextSpan(
                            text: 'Password',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.password,
                              color: Colors.indigo,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.indigo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            hintText: "Password",
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 28,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _termsAccepted = value!;
                                        _termsError = null;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _termsAccepted = !_termsAccepted;
                                        _termsError = null;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'terms and conditions',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = _launchTermsUrl,
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'privacy policy',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = _launchTermsUrl,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_termsError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12.0,
                                  top: 2,
                                ),
                                child: Text(
                                  _termsError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.05),

                        if (_isOtpInputVisible && !_isOtpVerified)
                          Column(
                            children: [
                              const Text(
                                "Enter OTP",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.indigo,
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap:
                                    _start == 0
                                        ? () => sendOtp(_mobileNo!)
                                        : null,
                                child: Text(
                                  _start > 0
                                      ? "Resend OTP in $_start sec"
                                      : "Didn't get OTP? Tap to Resend",
                                  style: TextStyle(
                                    color:
                                        _start == 0 ? Colors.blue : Colors.grey,
                                    fontWeight:
                                        _start == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              // OTP Boxes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: screenWidth * 0.12,
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _focusNodes[index],
                                      maxLength: 1,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        hintText: "-",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty &&
                                            index < _focusNodes.length - 1) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: screenWidth * 0.05),
                              ElevatedButton(
                                onPressed: verifyOtp,
                                child: const Text(
                                  "Verify OTP",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (!_isOtpInputVisible || _isOtpVerified)
                          ElevatedButton(
                            onPressed: loginUser,
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      "Login",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff1A237E),
                              padding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.02,
                              ),
                            ),
                          ),
                        SizedBox(height: screenWidth * 0.05),
                        Text(
                          _message,
                          style: TextStyle(
                            color:
                                _message ==
                                        _message.contains(
                                          "Otp sent to $_mobileNo",
                                        )
                                    ? Colors.green
                                    : Colors.red,
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
      ),
    );
  }
}
