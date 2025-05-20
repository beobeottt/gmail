import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Verification_Code.dart';
import 'package:get/get.dart';
import 'dart:io';

class RegisterPhonePage extends StatefulWidget {
  const RegisterPhonePage({Key? key}) : super(key: key);

  @override
  State<RegisterPhonePage> createState() => _RegisterPhonePageState();
}

class _RegisterPhonePageState extends State<RegisterPhonePage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> sendVerificationCode() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    if (phone.length < 9 || phone.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại phải có 9-10 chữ số')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if ((Platform.isIOS || Platform.isAndroid)) {
        // 💡 Simulator hoặc Emulator
        phone = '+16505551234'; // Số test của Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đang sử dụng số điện thoại test cho thiết bị giả lập',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 💡 Thiết bị thật
        if (!phone.startsWith('+')) {
          if (phone.startsWith('0')) {
            phone = '+1${phone.substring(1)}';
          } else {
            phone = '+1$phone';
          }
        }
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Xác minh thất bại: ';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage += 'Số điện thoại không hợp lệ';
              break;
            case 'too-many-requests':
              errorMessage += 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
              break;
            case 'network-request-failed':
              errorMessage += 'Lỗi kết nối mạng. Vui lòng kiểm tra lại';
              break;
            default:
              errorMessage += e.message ?? 'Lỗi không xác định';
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errorMessage)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => VerifyOtpPage(
                      phoneNumber: phone,
                      verificationId: verificationId,
                    ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mã xác minh hết hạn. Vui lòng thử lại'),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký bằng số điện thoại"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Nhập số điện thoại của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chúng tôi sẽ gửi mã xác minh đến số điện thoại này',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey)),
                    ),
                    // child: const Text(
                    //   '+1',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        if (value.startsWith('0')) {
                          _phoneController.text = value.substring(1);
                          _phoneController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _phoneController.text.length),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
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
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Gửi mã xác minh',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
