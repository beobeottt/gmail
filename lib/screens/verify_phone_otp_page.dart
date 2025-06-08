import 'package:flutter/material.dart';
import 'ResetPassword_Page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final int demoOtp;

  const VerifyOtpPage({
    Key? key,
    required this.phoneNumber,
    required this.email,
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

  void _verifyOtp() {
    final entered = _otpController.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã OTP')));
      return;
    }
    if (entered != widget.demoOtp.toString()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP không đúng')));
      return;
    }

    setState(() => _isVerifying = true);

    // Delay một chút, sau đó chuyển sang ChangePasswordPage
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChangePasswordPage(
                phoneNumber: widget.phoneNumber,
                email: widget.email,
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mã OTP đã gửi đến: ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Nhập mã OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              child:
                  _isVerifying
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Xác nhận OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
