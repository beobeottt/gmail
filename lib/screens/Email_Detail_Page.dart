import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailDetailPage extends StatefulWidget {
  final String emailId;

  const EmailDetailPage({Key? key, required this.emailId}) : super(key: key);

  @override
  _EmailDetailPageState createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  Future<void> _moveToTrash() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Lấy thông tin email hiện tại
      final emailDoc = await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.emailId)
          .get();

      if (!emailDoc.exists) return;

      final emailData = emailDoc.data()!;

      // Tính thời gian tự động xóa (30 ngày sau)
      final autoDeleteAt = DateTime.now().add(const Duration(days: 30));

      // Di chuyển vào collection trash
      await FirebaseFirestore.instance
          .collection('trash')
          .doc(widget.emailId)
          .set({
        ...emailData,
        'deletedAt': FieldValue.serverTimestamp(),
        'autoDeleteAt': Timestamp.fromDate(autoDeleteAt),
      });

      // Xóa khỏi collection emails
      await emailDoc.reference.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chuyển email vào thùng rác')),
      );
      Navigator.pop(context); // Quay lại trang trước
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chuyển vào thùng rác: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _moveToTrash,
            tooltip: 'Chuyển vào thùng rác',
          ),
        ],
      ),
      body: const Center(
        child: Text('Chi tiết Email'),
      ),
    );
  }
}
