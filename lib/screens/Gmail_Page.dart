// lib/screens/gmail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/email_model.dart';
import '../widgets/email_title.dart';
import 'Compose_Email_Page.dart';
import 'Account_Page.dart';
//import 'Email_Detail_Page.dart';
import 'Send_mail.dart';
import 'Starred_Page.dart';
import 'Home_Page.dart';
import 'Trash_Page.dart';
import 'draft_Page.dart';

class GmailPage extends StatefulWidget {
  const GmailPage({Key? key}) : super(key: key);

  @override
  State<GmailPage> createState() => _GmailPageState();
}

class _GmailPageState extends State<GmailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<Email>? _emails;
  Future<List<Email>>? _emailsFuture;

  @override
  void initState() {
    super.initState();
    _emailsFuture = fetchEmails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnreadCountNotification();
    });
  }

  Future<void> _showUnreadCountNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('emails')
        .where('to', isEqualTo: user.email!)
        .where('isDeleted', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .get();
    final unreadCount = snapshot.docs.length;
    if (unreadCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn có $unreadCount email chưa đọc'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<List<Email>> fetchEmails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        debugPrint('User not logged in');
        return [];
      }

      // Kiểm tra kết nối
      final hasConnection = await _checkConnection();
      if (!hasConnection) {
        throw Exception('Không có kết nối internet');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('emails')
          .where('to', isEqualTo: user.email!)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return Email.fromDoc(doc);
            } catch (e) {
              debugPrint('Error parsing email ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Email>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching emails: $e');
      throw e;
    }
  }

  void _refreshEmails() {
    setState(() {
      _emailsFuture = fetchEmails();
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _openEmailDetail(Email email) async {
    try {
      setState(() => _isLoading = true);


      await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .update({'isRead': true});

      // Kiểm tra email còn tồn tại không
      final doc = await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email không tồn tại hoặc đã bị xóa')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmailDetailPage(emailId: email.id)),
        ).then((_) => setState(() {}));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi mở email: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL != null) {
      return GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        ),
        child: CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!)),
      );
    }
    final initial = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName![0].toUpperCase()
        : '?';
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      ),
      child: CircleAvatar(child: Text(initial)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gmail'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Inbox'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GmailPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StarredPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SendMailPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.drafts),
              title: const Text('Drafts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Compose Email'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text(
                    'Are you sure you want to log out?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pop(ctx);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Search Mail',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildProfileAvatar(),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Email>>(
                future: _emailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Có lỗi xảy ra: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshEmails,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  final emails = snapshot.data ?? [];
                  if (emails.isEmpty) {
                    return const Center(
                      child: Text('Không có email nào.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _refreshEmails();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: emails.length,
                      itemBuilder: (context, i) {
                        final email = emails[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            child: Text(email.from.isNotEmpty
                                ? email.from[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(
                            email.subject,
                            style: TextStyle(
                              fontWeight: email.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: email.isRead ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Text(email.from),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  email.isStarred
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: email.isStarred
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  try {
                                    // Cập nhật Firestore trước
                                    await FirebaseFirestore.instance
                                        .collection('emails')
                                        .doc(email.id)
                                        .update(
                                            {'isStarred': !email.isStarred});

                                    // Refresh lại danh sách email để cập nhật UI
                                    _refreshEmails();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(!email.isStarred
                                              ? 'Đã đánh dấu Star'
                                              : 'Đã bỏ Star'),
                                          duration:
                                              const Duration(milliseconds: 800),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Lỗi khi cập nhật Starred: $e')),
                                      );
                                    }
                                  }
                                },
                                tooltip: email.isStarred ? 'Bỏ Star' : 'Star',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('emails')
                                        .doc(email.id)
                                        .update({'isDeleted': true});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Đã chuyển email vào Thùng Rác'),
                                      ),
                                    );
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const TrashPage()),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Lỗi khi di chuyển vào Thùng Rác: $e'),
                                      ),
                                    );
                                  }
                                },
                                tooltip: 'Move to Trash',
                              ),
                            ],
                          ),
                          onTap: () => _openEmailDetail(email),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
        ),
        tooltip: 'Compose',
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.red),
      ),
    );
  }
}
