import 'package:flutter/material.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Forgot_Password.dart';
import 'package:khoates/screens/Gmail_Page.dart';
import 'package:khoates/screens/Home_Page.dart' show HomePage;
import 'package:khoates/screens/Setting_Page.dart';
import 'Register_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _selectedIndex = 0;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future signIn() async {
    // check email, password is null
    final _email = _emailController.text.trim();
    final _password = _passwordController.text.trim();
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ email và mật khẩu.")),
      );
      return;
    }
    try {
      // login with real Account from firebase
      await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      // Chuyển đến HomePage nếu đăng nhập thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GmailPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login False!!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(child: buildLoginForm()),
    );
  }

  Widget buildLoginForm() {
    return Center(
      child: Container(
        width: 350,
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Demo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              'Sign In',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 20),

            // Email field
            buildTextField(_emailController, 'Email'),

            SizedBox(height: 20),

            // Password
            buildTextField(_passwordController, 'Password', isPassword: true),

            SizedBox(height: 20),

            // Sign in button
            GestureDetector(
              onTap: signIn,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Register text
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPhonePage()),
                );
              },
              child: Text(
                'Not a member? Register',
                style: TextStyle(color: Colors.blue),
              ),
            ),

            // Forgot Password
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String hintText, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType:
                isPassword ? TextInputType.text : TextInputType.emailAddress,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
            ),
          ),
        ),
      ),
    );
  }
}
