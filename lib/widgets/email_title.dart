import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        setState(() {}); // trigger FutureBuilder reload once update xong
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật Star: $e')),
      );
    } finally {
      // Dù thành công hay lỗi, tắt loading và reload lại FutureBuilder
      setState(() {
        _isUpdatingStar = false;
      });
      setState(() {});
    }
  }

  /// Di chuyển email vào Thùng Rác (isDeleted = true) và điều hướng sang trang TrashPage
  Future<void> _moveToTrash(Email email) async {
    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .update({'isDeleted': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email đã được chuyển vào Thùng Rác')),
      );
      if (!mounted) return;
      // Sau khi update xong, pushReplacement sang TrashPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrashPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi di chuyển: $e')),
      );
    }
  }

  /// Hiển thị danh sách attachments và cho phép mở đường dẫn tương ứng
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

  /// Chuyển sang màn soạn email với chế độ 'reply'
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

  /// Chuyển sang màn soạn email với chế độ 'replyAll'
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

  /// Chuyển sang màn soạn email với chế độ 'forward'
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
    // Dùng FutureBuilder để lấy document `/emails/{emailId}`
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.emailId)
          .get(),
      builder: (context, snapshot) {
        // === 1) Nếu đang chờ dữ liệu ===
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chi tiết Email'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // === 2) Nếu Firestore trả về lỗi (permission, network, v.v…) ===
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chi tiết Email'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text(
                'Đã có lỗi xảy ra:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // === 3) Nếu document không tồn tại hoặc dữ liệu null ===
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chi tiết Email'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text('Không tìm thấy email này')),
          );
        }

        // === 4) Document tồn tại → parse thành Email ===
        final email = Email.fromDoc(snapshot.data!);

        // Nếu email chưa đọc → đánh dấu isRead = true
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markAsReadIfNeeded(email);
        });

        // Format ngày tháng từ email.date
        final formattedDate =
            '${email.date.day}/${email.date.month}/${email.date.year}';

        // === 5) Trả về Scaffold đầy đủ với AppBar + Body khi đã có email ===
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết Email'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Nút Download Attachment
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
              // ========= Phần nội dung chính =========
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Subject ---
                      Text(
                        email.subject,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- From ---
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

                      // --- To ---
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

                      // --- Cc (nếu có) ---
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

                      // --- Bcc (nếu có) ---
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

                      // --- Date & Time ---
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

                      // --- Attachments (nếu có) ---
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
                                    border:
                                        Border.all(color: Colors.grey.shade400),
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
                                          child:
                                              Icon(Icons.image_not_supported),
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

                      // --- Body ---
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

              // ========= Ba nút “Reply / Reply All / Forward” =========
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- Reply ---
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

                    // --- Reply All ---
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

                    // --- Forward ---
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
            ],
          ),
        );
      },
    );
  }
}
