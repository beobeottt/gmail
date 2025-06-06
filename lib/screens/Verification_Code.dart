// lib/screens/verify_otp_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Nếu bạn muốn điều hướng về HomePage sau khi đăng ký xong:
import 'Home_Page.dart';
import 'login_page.dart';

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
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _verifyOtp() async {
    final input = _otpController.text.trim();
    if (input.isEmpty) {
      _showSnack('Vui lòng nhập mã OTP');
      return;
    }

    final enteredOtp = int.tryParse(input);
    if (enteredOtp == null) {
      _showSnack('OTP chỉ gồm chữ số');
      return;
    }

    if (enteredOtp != widget.demoOtp) {
      _showSnack('Mã OTP không đúng');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      debugPrint('≫ Entered OTP: $enteredOtp, Demo OTP: ${widget.demoOtp}');
      debugPrint('≫ Creating user with email=${widget.email}');

      // 1) Tạo account bằng email/password
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      User firebaseUser = cred.user!;
      debugPrint('≫ Firebase user created, UID=${firebaseUser.uid}');

      // 2) Cập nhật displayName
      await firebaseUser.updateDisplayName(widget.name);
      debugPrint('≫ Updated displayName to ${widget.name}');

      // 3) Tạo document profile trong Firestore
      final uid = firebaseUser.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': widget.name,
        'dob': widget.dob,
        'email': widget.email,
        'phone': widget.phone,
        'photoURL': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('≫ Firestore profile document created for UID=$uid');

      // 4) Điều hướng về HomePage
      if (!mounted) return;
      debugPrint('≫ Điều hướng về HomePage');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      debugPrint('≫ Đã gọi pushAndRemoveUntil tới HomePage');
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email này đã được sử dụng.';
          break;
        case 'invalid-email':
          message = 'Định dạng email không hợp lệ.';
          break;
        case 'weak-password':
          message = 'Mật khẩu quá yếu.';
          break;
        default:
          message = e.message ?? 'Lỗi đăng ký: ${e.code}';
      }
      _showSnack(message);
      debugPrint('≫ FirebaseAuthException: ${e.code} / ${e.message}');
    } catch (e) {
      _showSnack('Đã có lỗi xảy ra: ${e.toString()}');
      debugPrint('≫ Exception in _verifyOtp: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
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
            const SizedBox(height: 20),
            Text(
              'Chúng tôi đã gửi mã OTP đến số 0${widget.phone}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập mã OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Xác nhận OTP',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
