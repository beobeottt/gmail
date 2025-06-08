import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  final String phoneNumber;
  final String email;

  const ChangePasswordPage({
    Key? key,
    required this.phoneNumber,
    required this.email,
  }) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if (newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu và xác nhận')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu và xác nhận không khớp')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // 1) Đầu tiên: update password trong Firebase Authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng chưa đăng nhập')),
        );
        setState(() => _isUpdating = false);
        return;
      }

      // Lưu lại email để reauthenticate nếu cần (nếu sign-in tạm thời bằng OTP phone)
      // Nếu bạn sign-in tạm bằng phone, không cần re-auth. Nhưng nếu user sign-in bằng email/password cũ,
      // bạn có thể reauthenticate trước khi đổi mật khẩu:
      // final cred = EmailAuthProvider.credential(email: widget.email, password: oldPassword);
      // await currentUser.reauthenticateWithCredential(cred);

      // Giờ gọi updatePassword
      await currentUser.updatePassword(newPass);

      // 2) Tiếp theo (tuỳ bạn): nếu bạn vẫn muốn giữ Firestore’s “users” document có trường `password`,
      // bạn có thể update thêm ở Firestore, nhưng thường để tránh trùng dữ liệu nên bạn CC/copy ghi `password` ở Firestore
      // chỉ dùng nội bộ, còn bản xác thực chính là ở FirebaseAuth.
      //
      // Nếu muốn đồng bộ, hãy làm như sau (tự chọn):
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: widget.phoneNumber)
              .where('email', isEqualTo: widget.email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({'password': newPass});
      }

      // 3) Sau khi đổi xong, sign out user (vì họ đã sign-in tạm thời qua OTP)
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
        ),
      );

      // 4) Quay về màn hình đăng nhập (ví dụ route '/login'):
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi khi cập nhật mật khẩu';
      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu.';
      } else if (e.code == 'requires-recent-login') {
        message =
            'Yêu cầu đăng nhập lại để thay đổi mật khẩu. Hãy đăn g nhập lại rồi thử lại.';
      } else if (e.message != null) {
        message = e.message!;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isUpdating = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bạn đang đổi mật khẩu cho tài khoản:\n'
                      'Phone: ${widget.phoneNumber}\n'
                      'Email: ${widget.email}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: const Text('Cập nhật mật khẩu'),
                    ),
                  ],
                ),
      ),
    );
  }
}
