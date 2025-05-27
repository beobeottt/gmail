import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Verification_Code.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class RegisterPhonePage extends StatefulWidget {
  const RegisterPhonePage({Key? key}) : super(key: key);

  @override
  State<RegisterPhonePage> createState() => _RegisterPhonePageState();
}

class _RegisterPhonePageState extends State<RegisterPhonePage> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  int? _demoOtp;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> sendVerificationCode() async {
    // Validate input
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập tên');
      return;
    }
    if (_dobController.text.trim().isEmpty) {
      _showSnack('Vui lòng chọn ngày sinh');
      return;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _showSnack('Vui lòng nhập email hợp lệ');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showSnack('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Vui lòng nhập số điện thoại');
      return;
    }
    if (phone.length < 9 || phone.length > 10) {
      _showSnack('Số điện thoại phải có 9-10 chữ số');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Generate demo OTP
    _demoOtp = math.Random().nextInt(900000) + 100000;
    _showSnack('Mã OTP demo: $_demoOtp');

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => VerifyOtpPage(
                name: _nameController.text.trim(),
                dob: _dobController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                phone: phone,
                demoOtp: _demoOtp!,
              ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _dobController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Ngày sinh',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (value.startsWith('0')) {
                  _phoneController.text = value.substring(1);
                  _phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _phoneController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : sendVerificationCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng ký', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
