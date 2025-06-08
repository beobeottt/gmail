// lib/screens/Trash_Page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/email_model.dart';
import '../widgets/email_title.dart';
//import 'email_detail_page.dart';

class TrashPage extends StatelessWidget {
  const TrashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng Rác'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query cần index: where + orderBy
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('isDeleted', isEqualTo: true)
            //.orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Khi Firestore chưa trả dữ liệu, hiển thị spinner
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Nếu có lỗi (chẳng hạn index chưa built), hiển thị thông báo
            return Center(
              child: Text(
                'Lỗi khi tải Thùng rác:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            // Khi snapshot có data nhưng rỗng => Thùng rác trống
            return const Center(child: Text('Thùng rác trống'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final email = Email.fromDoc(docs[index]);
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  child: Text(
                    email.from.isNotEmpty ? email.from[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(
                  email.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                subtitle: Text('${email.from} • ${email.time}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailPage(emailId: email.id),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Xóa vĩnh viễn',
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('emails')
                          .doc(email.id)
                          .delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Email đã bị xóa vĩnh viễn')),
                        );
                        // Pop TrashPage để quay về EmailDetailPage, rồi EmailDetailPage sẽ tự pop để về GmailPage
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi xóa vĩnh viễn: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
