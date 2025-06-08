import 'dart:math';
import 'package:flutter/material.dart';
import 'verify_phone_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSendingOtp = false;
  int? _demoOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _sendDemoOtp() {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ số điện thoại và email'),
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    // 1) Sinh OTP ngẫu nhiên 6 chữ số
    _demoOtp = Random().nextInt(900000) + 100000; // 100000 - 999999

    // 2) Hiển thị OTP bằng Snackbar (chỉ demo; thực tế bạn cần gửi SMS)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mã OTP (demo): $_demoOtp')));

    // 3) Delay một chút để user kịp xem SnackBar, sau đó điều hướng sang VerifyOtpPage
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => VerifyOtpPage(
                phoneNumber: phone,
                email: email,
                demoOtp: _demoOtp!,
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: '0912345678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'ví dụ: abc@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSendingOtp ? null : _sendDemoOtp,
              child:
                  _isSendingOtp
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Gửi mã OTP (Demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
