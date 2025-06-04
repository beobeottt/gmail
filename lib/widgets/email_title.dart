// lib/screens/email_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/email_model.dart';
import '../screens/Trash_Page.dart';

class EmailDetailPage extends StatefulWidget {
  final String emailId;

  const EmailDetailPage({Key? key, required this.emailId}) : super(key: key);

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  bool _isLoading = true;
  late Email _email;
  bool _isUpdatingStar = false;

  @override
  void initState() {
    super.initState();
    _fetchEmail();
  }

  Future<void> _fetchEmail() async {
    final doc = await FirebaseFirestore.instance
        .collection('emails')
        .doc(widget.emailId)
        .get();
    if (!doc.exists) {
      // Nếu không tìm thấy email, pop ra
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _email = Email.fromDoc(doc);
      _isLoading = false;
    });
    _markAsReadIfNeeded();
  }

  Future<void> _markAsReadIfNeeded() async {
    if (!_email.isRead) {
      try {
        await FirebaseFirestore.instance
            .collection('emails')
            .doc(_email.id)
            .update({'isRead': true});
        setState(() {
          _email = _email.copyWith(isRead: true);
        });
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }

  Future<void> _toggleStarred() async {
    setState(() => _isUpdatingStar = true);
    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(_email.id)
          .update({'isStarred': !_email.isStarred});
      setState(() {
        _email = _email.copyWith(isStarred: !_email.isStarred);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStar = false);
    }
  }

  Future<void> _downloadAttachment() async {
    // Nếu không có attachments, hiện SnackBar
    if (_email.attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có file đính kèm')),
      );
      return;
    }

    // Hiển thị bottom sheet liệt kê attachments
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: _email.attachments.length,
        itemBuilder: (context, index) {
          final att = _email.attachments[index];
          return ListTile(
            leading: const Icon(Icons.attachment),
            title: Text(att.name),
            subtitle: Text(att.url),
            onTap: () async {
              final uri = Uri.parse(att.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể mở đường dẫn ${att.url}')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _moveToTrash() async {
    try {
      // Đánh dấu email vào thùng rác
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(_email.id)
          .update({'isDeleted': true});

      setState(() {
        _email = _email.copyWith(isDeleted: true);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email đã được chuyển vào Thùng rác')),
        );
        // Điều hướng sang TrashPage (push, không pushReplacement)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrashPage()),
        ).then((_) {
          // Khi trở về từ TrashPage, pop luôn EmailDetailPage để quay về GmailPage
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi di chuyển: $e')),
        );
      }
    }
  }

  void _onReply() {
    // TODO: chuyển đến trang soạn email với mode = reply
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reply chưa implement')));
  }

  void _onReplyAll() {
    // TODO: chuyển đến trang soạn email với mode = replyAll
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply All chưa implement')));
  }

  void _onForward() {
    // TODO: chuyển đến trang soạn email với mode = forward
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Forward chưa implement')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          // Download attachment
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download Attachment',
            onPressed: _downloadAttachment,
          ),
          // Move to Trash
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Move to Trash',
            onPressed: _moveToTrash,
          ),
          // Star / Unstar
          IconButton(
            icon: _isUpdatingStar
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : Icon(
                    _email.isStarred ? Icons.star : Icons.star_border,
                    color: _email.isStarred ? Colors.orange : Colors.black,
                  ),
            tooltip: _email.isStarred ? 'Unstar' : 'Star',
            onPressed: _isUpdatingStar ? null : _toggleStarred,
          ),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subject
                  Text(
                    _email.subject,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                              color:
                                  _email.isRead ? Colors.grey : Colors.black),
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
                              color:
                                  _email.isRead ? Colors.grey : Colors.black),
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
                  // Attachments (nếu có)
                  if (_email.attachments.isNotEmpty) ...[
                    const Text(
                      'File đính kèm:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _email.attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _email.attachments[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  attachment.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                  ],
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _email.body,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _email.isRead ? Colors.grey[700] : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Ba nút Reply / Reply All / Forward
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reply
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.reply_rounded),
                    label: const Text('Reply'),
                    onPressed: _onReply,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                // Reply All
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.reply_all_rounded),
                    label: const Text('Reply All'),
                    onPressed: _onReplyAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                // Forward
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.forward_rounded),
                    label: const Text('Forward'),
                    onPressed: _onForward,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
