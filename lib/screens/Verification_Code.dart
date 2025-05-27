// verify_otp_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoates/screens/Gmail_Page.dart';
import 'package:pinput/pinput.dart';

import 'Home_Page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String name;
  final String dob;
  final String email;
  final String password;
  final String phone;
  final int demoOtp;

  const VerifyOtpPage({
    Key? key,
    required this.name,
    required this.dob,
    required this.email,
    required this.password,
    required this.phone,
    required this.demoOtp,
  }) : super(key: key);

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    final input = _otpController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập OTP')));
      return;
    }
    if (int.tryParse(input) != widget.demoOtp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP không đúng')));
      return;
    }

    // 1) Show loading indicator
    if (mounted) setState(() => _isVerifying = true);

    try {
      // 2) Create user with email & password
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
      String uid = cred.user!.uid;

      // 3) Save additional profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': widget.name,
        'dob': widget.dob,
        'email': widget.email,
        'password': widget.password,
        'phone': widget.phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4) Navigate to HomePage before clearing loading
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const GmailPage()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi Firebase: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      // 5) Only reset loading if widget is still mounted
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nhập mã OTP đã gửi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // You can replace this TextField with Pinput if you prefer:
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              child:
                  _isVerifying
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : const Text('Xác nhận', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
