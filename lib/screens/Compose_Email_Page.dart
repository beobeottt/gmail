import 'package:flutter/material.dart';

class ComposeEmailPage extends StatefulWidget {
  @override
  _ComposeEmailPageState createState() => _ComposeEmailPageState();
}

class _ComposeEmailPageState extends State<ComposeEmailPage> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  void _sendEmail() {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
      return;
    }

    // Xử lý gửi email tại đây (hoặc dùng gói như mailer, firebase, api)
    print("Đang gửi email đến: $to\nChủ đề: $subject\nNội dung: $body");

    // Reset form
    _toController.clear();
    _subjectController.clear();
    _bodyController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Email đã được gửi")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Quay lại trang trước
          },
        ),
        title: Text("Soạn Email"),
        actions: [IconButton(icon: Icon(Icons.send), onPressed: _sendEmail)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _toController,
              decoration: InputDecoration(
                labelText: "Đến",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Chủ đề",
                prefixIcon: Icon(Icons.subject),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: InputDecoration(
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
