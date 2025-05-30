import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComposeEmailPage extends StatefulWidget {
  const ComposeEmailPage({Key? key}) : super(key: key);

  @override
  _ComposeEmailPageState createState() => _ComposeEmailPageState();
}

class _ComposeEmailPageState extends State<ComposeEmailPage> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    final from = FirebaseAuth.instance.currentUser?.email;

    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }
    if (from == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn phải đăng nhập để gửi email")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1) Lưu vào Firestore
      await FirebaseFirestore.instance.collection('emails').add({
        'from': from,
        'to': to,
        'subject': subject,
        'body': body,
        'time': DateTime.now().toIso8601String(),
        'isTopItem': false,
        'isRead': true,
        'isSent': true,
        'icon': 'send',
      });

      // 2) Reset form & thông báo
      _toController.clear();
      _subjectController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email đã được lưu và gửi")));

      // 3) Quay về inbox hoặc page khác (tuỳ bạn)
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi gửi: ${e.toString()}")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Soạn Email"),
        actions: [
          IconButton(
            icon:
                _isSending
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendEmail,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: "Đến",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Chủ đề",
                prefixIcon: Icon(Icons.subject),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: "Nội dung",
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
