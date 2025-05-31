// lib/screens/email_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/email_model.dart';

class EmailDetailPage extends StatefulWidget {
  final Email email;

  const EmailDetailPage({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  late Email _email;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _markAsReadIfNeeded();
  }

  Future<void> _markAsReadIfNeeded() async {
    // Nếu email chưa được đánh dấu là đã đọc, cập nhật lên Firestore
    if (!_email.isRead) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('emails')
              .doc(_email.id)
              .update({'isRead': true});
          setState(() {
            _email = Email(
              id: _email.id,
              from: _email.from,
              to: _email.to,
              subject: _email.subject,
              body: _email.body,
              date: _email.date,
              time: _email.time,
              isRead: true,
              isStarred: _email.isStarred,
            );
          });
        } catch (e) {
          // Bỏ qua lỗi nhẹ, chỉ in ra log
          debugPrint('Error marking as read: $e');
        }
      }
    }
  }

  Future<void> _toggleStarred() async {
    setState(() {
      _isUpdating = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(_email.id)
          .update({'isStarred': !_email.isStarred});

      setState(() {
        _email = Email(
          id: _email.id,
          from: _email.from,
          to: _email.to,
          subject: _email.subject,
          body: _email.body,
          date: _email.date,
          time: _email.time,
          isRead: _email.isRead,
          isStarred: !_email.isStarred,
        );
      });
    } catch (e) {
      debugPrint('Error toggling starred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái Starred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_email.date.day}/${_email.date.month}/${_email.date.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                _isUpdating
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : Icon(
                      _email.isStarred ? Icons.star : Icons.star_border,
                      color: _email.isStarred ? Colors.orange : Colors.white,
                    ),
            onPressed: _isUpdating ? null : _toggleStarred,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject
            Text(
              _email.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // From / To / Date & Time
            Row(
              children: [
                const Text(
                  'From: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    _email.from,
                    style: TextStyle(
                      color: _email.isRead ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'To: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    _email.to,
                    style: TextStyle(
                      color: _email.isRead ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Date: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('$formattedDate  -  ${_email.time}'),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            // Body
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _email.body,
                  style: TextStyle(
                    fontSize: 16,
                    color: _email.isRead ? Colors.grey[700] : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
