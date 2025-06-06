// lib/screens/email_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/email_model.dart';

class EmailDetailPage extends StatelessWidget {
  final String emailId;

  const EmailDetailPage({Key? key, required this.emailId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('emails').doc(emailId).get(),
        builder: (context, snapshot) {
          // 1) Chưa có dữ liệu → hiện loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2) Firestore trả về lỗi (ví dụ: permission-denied, hay network-error)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã có lỗi xảy ra:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 3) Nguyen dữ liệu null hoặc document không tồn tại
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy email này'));
          }

          // 4) Document tồn tại → parse thành Email
          final doc = snapshot.data!;
          final email = Email.fromDoc(doc);

          // 5) Build UI hiển thị thông tin email
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề (subject)
                Text(
                  email.subject,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // From
                Row(
                  children: [
                    const Text(
                      'From: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(email.from),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // To
                Row(
                  children: [
                    const Text(
                      'To: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(email.to),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nếu có cc
                if (email.cc.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'Cc: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(email.cc.join(', '))),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Nếu có bcc
                if (email.bcc.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'Bcc: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(email.bcc.join(', '))),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Ngày / giờ
                Row(
                  children: [
                    const Text(
                      'Date: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '${email.date.day}/${email.date.month}/${email.date.year}  –  ${email.time}'),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Nội dung thân email (body)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      email.body,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
