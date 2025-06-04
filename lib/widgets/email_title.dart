// lib/screens/email_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/email_model.dart';
import '../screens/Compose_Email_Page.dart';
import '../screens/Trash_Page.dart';

class EmailDetailPage extends StatefulWidget {
  final String emailId;

  const EmailDetailPage({Key? key, required this.emailId}) : super(key: key);

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  bool _isUpdatingStar = false;

  /// Nếu email chưa đọc, cập nhật isRead = true trong Firestore
  Future<void> _markAsReadIfNeeded(Email email) async {
    if (!email.isRead) {
      try {
        await FirebaseFirestore.instance
            .collection('emails')
            .doc(email.id)
            .update({'isRead': true});
        setState(() {}); // Kích rebuild để FutureBuilder refetch
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }

  /// Toggle trạng thái Star / Unstar
  Future<void> _toggleStarred(Email email) async {
    setState(() => _isUpdatingStar = true);
    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .update({'isStarred': !email.isStarred});
      setState(() => _isUpdatingStar = false);
    } catch (e) {
      setState(() => _isUpdatingStar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật star: $e')),
        );
      }
    }
  }

  /// Di chuyển email vào Thùng rác (isDeleted = true) và điều hướng sang TrashPage
  Future<void> _moveToTrash(Email email) async {
    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .update({'isDeleted': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email đã được chuyển vào Thùng rác')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrashPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi di chuyển: $e')),
        );
      }
    }
  }

  /// Hiển thị danh sách attachments và cho phép mở đường dẫn
  void _downloadAttachment(Email email) {
    if (email.attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có file đính kèm')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: email.attachments.length,
        itemBuilder: (context, index) {
          final att = email.attachments[index];
          return ListTile(
            leading: const Icon(Icons.attachment),
            title: Text(att.name),
            subtitle: Text(att.url),
            onTap: () async {
              final uri = Uri.parse(att.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể mở đường dẫn ${att.url}'),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  /// Chuyển sang màn soạn email với chế độ ‘reply’
  void _onReply(Email email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeEmailPage(
          mode: 'reply',
          originalEmail: email,
        ),
      ),
    );
  }

  /// Chuyển sang màn soạn email với chế độ ‘replyAll’
  void _onReplyAll(Email email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeEmailPage(
          mode: 'replyAll',
          originalEmail: email,
        ),
      ),
    );
  }

  /// Chuyển sang màn soạn email với chế độ ‘forward’
  void _onForward(Email email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeEmailPage(
          mode: 'forward',
          originalEmail: email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.emailId)
          .get(),
      builder: (context, snapshot) {
        // Đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Nếu không có document (hoặc doc không tồn tại)
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết Email')),
            body: const Center(child: Text('Không tìm thấy email này')),
          );
        }

        // Đã có data, map sang Email
        final email = Email.fromDoc(snapshot.data!);

        // Nếu email chưa đọc, đánh dấu đọc ngay sau khi UI build xong
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markAsReadIfNeeded(email);
        });

        // Định dạng ngày/tháng/năm từ email.date
        final formattedDate =
            '${email.date.day}/${email.date.month}/${email.date.year}';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết Email'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Nút Download attachment
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Download Attachment',
                onPressed: () => _downloadAttachment(email),
              ),

              // Nút Move to Trash
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Move to Trash',
                onPressed: () => _moveToTrash(email),
              ),

              // Nút Star / Unstar
              IconButton(
                icon: _isUpdatingStar
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(
                        email.isStarred ? Icons.star : Icons.star_border,
                        color: email.isStarred ? Colors.orange : Colors.white,
                      ),
                tooltip: email.isStarred ? 'Unstar' : 'Star',
                onPressed: _isUpdatingStar ? null : () => _toggleStarred(email),
              ),
            ],
          ),
          body: Column(
            children: [
              // =============================================
              // PHẦN NỘI DUNG CHÍNH (scrollable nếu quá dài)
              // =============================================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----- Subject -----
                      Text(
                        email.subject,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ----- From -----
                      Row(
                        children: [
                          const Text(
                            'From: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              email.from,
                              style: TextStyle(
                                color:
                                    email.isRead ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ----- To -----
                      Row(
                        children: [
                          const Text(
                            'To: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              email.to,
                              style: TextStyle(
                                color:
                                    email.isRead ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ----- Cc (nếu có) -----
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

                      // ----- Bcc (nếu có) -----
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

                      // ----- Date & Time -----
                      Row(
                        children: [
                          const Text(
                            'Date: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$formattedDate  -  ${email.time}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // ----- Attachments (nếu có) -----
                      if (email.attachments.isNotEmpty) ...[
                        const Text(
                          'File đính kèm:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: email.attachments.length,
                            itemBuilder: (context, index) {
                              final attachment = email.attachments[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      attachment.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                          ),
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

                      // ----- Body -----
                      Text(
                        email.body,
                        style: TextStyle(
                          fontSize: 16,
                          color: email.isRead ? Colors.grey[700] : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // PHẦN CUỐI: Ba nút “Reply / Reply All / Forward”
              // Mỗi nút có viền border riêng
              // ==================================================
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ----- Reply -----
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.reply_rounded),
                        label: const Text('Reply'),
                        onPressed: () => _onReply(email),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),

                    // ----- Reply All -----
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.reply_all_rounded),
                        label: const Text('Reply All'),
                        onPressed: () => _onReplyAll(email),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),

                    // ----- Forward -----
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.forward_rounded),
                        label: const Text('Forward'),
                        onPressed: () => _onForward(email),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ==================================================
            ],
          ),
        );
      },
    );
  }
}
