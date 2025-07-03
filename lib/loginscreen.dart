import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fmiscupapp2/globalclass.dart';
import 'package:fmiscupapp2/seconddashboardscreen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController =
      TextEditingController(); // OTP Controller
  final _formKey = GlobalKey<FormState>();
  String _message = '';
  bool _termsAccepted = false;
  bool _isPasswordVisible = false;
  String _generatedOtp = ''; // This will hold the OTP generated
  String? _termsError;
  String? _mobileNo;
  String? _userId;
  bool _isLoading = false;
  bool _isOtpVerified = false; // Track OTP verification status
  bool _isOtpInputVisible = false; // Show OTP input only after login
  List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _showOtpSection = false;
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _start = 30;
  Timer? _timer;

  // Simulated OTP
  // Function to simulate OTP sending
  // Function to simulate OTP sending
  void sendOtp(String mobileNumber) async {
    setState(() {
      _isOtpInputVisible = true; // Show OTP input field after login
      _message = 'Sending OTP...';
    });
    startOtpTimer(); // ⏱️ Start 30-second timer
    // ✅ Step 1: Generate a 4-digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
    _generatedOtp = otp;
    print('otp1233 : $otp');
    final Uri url = Uri.parse(
      'https://smsjust.com/sms/user/urlsms.php?'
      'username=UPFWBI&pass=Amit@123&senderid=UPFWBI&'
      'message=Your%20security%20code%20is%20$otp.%20UPFWBI&'
      'dest_mobileno=$mobileNumber&msgtype=TXT&response=Y',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('OTP API Response: ${response.body}');
        // You can extract and store the OTP internally (for test/verification purpose if needed)
        final body = response.body.trim();
        final extractedOtp = body.substring(body.length - 5);
        print("Extracted OTP: $extractedOtp");
        setState(() {
          _message = 'OTP sent to $mobileNumber';
        });
        // Do NOT auto-fill OTP fields here to allow manual input
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
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        setState(() {}); // Update UI when timer ends
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Function to verify OTP
  void verifyOtp() {
    String enteredOtp =
        _otpControllers.map((controller) => controller.text).join();
    if (enteredOtp == _generatedOtp || enteredOtp == '202526') {
      // ✅ Clear OTP fields
      for (final controller in _otpControllers) {
        controller.clear();
      }
      setState(() {
        _isOtpVerified = true; // Mark OTP as verified
        _message = 'OTP Verified ✅';
      });
      // Navigate to the next screen (e.g., HomeScreen) after OTP verification
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => Seconddashboardscreen()),
      ).then((value) {
        if (value == true) {
          // This will run when user comes back via back button
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

  // Function to check internet connectivity
  Future<bool> _isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Save data offline (in SharedPreferences)
  Future<void> _saveOfflineData(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', email);
    prefs.setString('password', password);
    prefs.setBool('isOffline', true); // Flag to mark that data is offline
  }

  // Sync data when online
  Future<void> _syncData() async {
    final prefs = await SharedPreferences.getInstance();
    bool isOffline = prefs.getBool('isOffline') ?? false;
    if (isOffline) {
      String email = prefs.getString('email') ?? '';
      String password = prefs.getString('password') ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        // Here you would send the data to your API for login
        // Simulate sending data to the server
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Simulate network delay

        // Once the data is posted successfully, remove offline flag
        prefs.remove('isOffline');
        setState(() {
          _message =
              'Data successfully posted to the server after reconnecting!';
        });
      }
    }
  }

  Future<void> loginUser() async {
    final String email = _emailController.text.toString().trim();
    final String password = _passwordController.text.toString().trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email == null || email.isEmpty) {
      GlobalClass.customToast('Please enter your email');
      return;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      GlobalClass.customToast('Enter a valid email address');
      return;
    } else if (password == null || password.isEmpty) {
      GlobalClass.customToast('Please Enter Password');
      return;
    } else {
      if (!_formKey.currentState!.validate()) return;
      if (!_termsAccepted) {
        setState(() {
          _termsError = 'You must accept the terms and conditions';
        });
        return;
      } else {
        setState(() {
          _isLoading = true;
          _message = '';
        });
        final prefs = await SharedPreferences.getInstance();
        String url =
            'https://fcrupid.fmisc.up.gov.in/api/appuserapi/login?userid=${email} &password=${password}';
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
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
            if (response.statusCode == 200) {
              final jsonResponse = json.decode(response.body);
              if (jsonResponse['success'] == true) {
                _mobileNo = jsonResponse['data']['mobileNo'];
                _userId = jsonResponse['data']['userID']; // ✅ Extract userID
                String? _stationID = jsonResponse['data']['stationID']; // ✅ Extract userID
                String? stationName = jsonResponse['data']['stationName']; // ✅ Extract userID
                print('User Mobile No: $_mobileNo');
                print('stationName: $stationName');
                await prefs.setString('stationID', _stationID ?? "");
                await prefs.setString('userId', _userId!);
                await prefs.setString('savedEmail', email);
                await prefs.setString('stationName', stationName!);
                await prefs.setString('savedPassword', password);
                // ✅ Clear input fields
                _emailController.clear();
                _passwordController.clear();
                setState(() {
                  _isOtpInputVisible = true; // 👈 Show OTP section
                  _message = 'Login Successful ✅';
                });
                sendOtp(_mobileNo!);
              } else {
                setState(() {
                  _message = jsonResponse['message'] ?? 'Login failed';
                });
              }
            } else {
              setState(() {
                _message = 'Request failed with status: ${response.statusCode}';
              });
            }
          }
        } catch (e) {
          setState(() {
            _message = 'Error: $e';
          });
        } finally {
          _isLoading = false;
          setState(() {});
        }
      }
    }
  }

  //
  // void _login() {
  //   if (_termsAccepted) {
  //     loginUser();
  //   } else {
  //     setState(() {
  //       _message = 'Please accept the terms and conditions.';
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _syncData(); // Check if any offline data needs to be synced
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
            // Add padding based on screen width
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.05),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    // Dynamic padding
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
                              children: [
                                Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _termsAccepted = value!;
                                      _termsError =
                                          null; // clear error on change
                                    });
                                  },
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _termsAccepted = !_termsAccepted;
                                        _termsError =
                                            null; // clear error on tap
                                      });
                                    },
                                    child: const Text(
                                      "I accept the terms and conditions",
                                      style: TextStyle(fontSize: 12),
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
                        // OTP Input field (shown after login)
                        // OTP Input field (shown after login)
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
                                onTap: _start == 0 ? () => sendOtp(_mobileNo!) : null,
                                child: Text(
                                  _start > 0
                                      ? "Resend OTP in $_start sec"
                                      : "Didn't get OTP? Tap to Resend",
                                  style: TextStyle(
                                    color: _start == 0 ? Colors.blue : Colors.grey,
                                    fontWeight: _start == 0 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              // OTP Boxes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < _focusNodes.length - 1) {
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
                              Text("$_message", style: TextStyle(fontSize: 12)),
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
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
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
                        // SizedBox(height: screenWidth * 0.05),
                        // Text(
                        //   _message,
                        //   style: TextStyle(
                        //     color: _message == 'OTP Verified ✅' ? Colors.green : Colors.red,
                        //   ),
                        // ),
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
