import 'package:flutter/material.dart';
import 'package:khoates/screens/otp.dart' show OTPScreen;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Auth')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    'Phone Authentication',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 40, right: 10, left: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    prefix: Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('+84'),
                    ),
                  ),
                  maxLength: 10,
                  keyboardType: TextInputType.number,
                  controller: _controller,
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.all(10),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                final phone = '+84${_controller.text.trim()}';
                if (_controller.text.length == 10) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => OTPScreen(phone)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid 10-digit phone number',
                      ),
                    ),
                  );
                }
              },
              child: Text('Next', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
