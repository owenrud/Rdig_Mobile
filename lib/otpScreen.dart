import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:main/global_variable.dart';

class OTPScreen extends StatefulWidget {
  final String email;

  OTPScreen({required this.email});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpDigitControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9575CD), // Set app bar color
        title: Text('OTP Verification'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF9575CD), Color(0XFFBA68C8)],
            stops: [0.1, 0.9],
            tileMode: TileMode.mirror,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'We have sent OTP code to your email:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.email,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Enter OTP Code:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 4; i++) _buildOTPDigitField(i),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOTP,
                child: Text('Verify OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPDigitField(int index) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _otpDigitControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(fontSize: 20),
        onChanged: (value) {
          // Move focus to the next text field when a digit is entered
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  void _verifyOTP() async {
    String otp = _otpController.text;
    for (int i = 0; i < 4; i++) {
      otp += _otpDigitControllers[i].text;
    }

    print('OTP entered: $otp');
    // print(otp);
    if (otp.length != 4) {
      // Display error message if OTP is not 4 digits
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid OTP'),
            content: Text('Please enter a 4-digit OTP.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Make API call to verify OTP
    final response = await http.post(
      Uri.parse('http://$ipAddress:8000/api/verify/otp'),
      body: {'email': widget.email, 'otp': otp},
    );

    if (response.statusCode == 200) {
      // OTP verification successful
      Navigator.of(context).popUntil((route) => route.isFirst);
      print('OTP verification successful');
    } else {
      // OTP verification failed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('OTP Verification Failed'),
            content: Text('Please enter a valid OTP.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      print('OTP verification failed');
      print('Error: ${response.body}');
    }
  }
}
