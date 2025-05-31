// lib/screens/verify_otp_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Nếu bạn muốn điều hướng về HomePage sau khi đăng ký xong:
import 'Home_Page.dart';

// Nếu bạn muốn dùng Pinput thay cho TextField, hãy cài thêm package pinput
// và mở comment đoạn mã bên dưới:
// import 'package:pinput/pinput.dart';

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
    // Hiển thị Snackbar ngắn gọn
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

    // Bắt đầu quá trình verify + sign-up
    setState(() {
      _isVerifying = true;
    });

    try {
      // 1) Tạo account bằng email/password
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
      User firebaseUser = cred.user!;

      // 2) Cập nhật displayName (nếu cần)
      await firebaseUser.updateDisplayName(widget.name);

      // 3) Tạo document profile trong Firestore với ID = uid
      final uid = firebaseUser.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': widget.name,
        'dob': widget.dob,
        'email': widget.email,
        'phone': widget.phone,
        'photoURL': '', // Có thể cập nhật sau
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4) Điều hướng sang HomePage (hoặc GmailPage nếu bạn muốn)
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      // Bắt các lỗi từ FirebaseAuth (email đã tồn tại, mật khẩu yếu, v.v.)
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
    } catch (e) {
      _showSnack('Đã có lỗi xảy ra: ${e.toString()}');
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

            // Nếu bạn muốn dùng Pinput thay cho TextField, bỏ comment đoạn dưới
            /*
            Center(
              child: Pinput(
                length: 6,
                controller: _otpController,
                onCompleted: (pin) => _verifyOtp(),
              ),
            ),
            */

            // Dùng TextField đơn giản để nhập OTP
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
