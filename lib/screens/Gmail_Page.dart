// lib/screens/gmail_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/email_model.dart';
import 'Account_Page.dart';
import 'Compose_Email_Page.dart';
import 'Email_Detail_Page.dart';
import 'Home_Page.dart';
import 'Send_mail.dart';
import 'Starred_Page.dart';
import 'Trash_Page.dart';
import 'draft_Page.dart';

class GmailPage extends StatefulWidget {
  const GmailPage({Key? key}) : super(key: key);

  @override
  State<GmailPage> createState() => _GmailPageState();
}

class _GmailPageState extends State<GmailPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Email>> _emailsFuture;

  // show/hide the in-line search field
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // loading / error state
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEmails();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnreadCountNotification();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEmails() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _emailsFuture = fetchEmails();
    });
  }

  Future<void> _showUnreadCountNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('emails')
        .where('to', isEqualTo: user!.email!)
        .where('isDeleted', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .get();
    final cnt = snap.docs.length;
    if (cnt > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn có $cnt email chưa đọc'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _checkConnection() async {
    try {
      final res = await InternetAddress.lookup('google.com');
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<List<Email>> fetchEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return [];
    if (!await _checkConnection()) {
      throw Exception('Không có kết nối internet');
    }
    final snap = await FirebaseFirestore.instance
        .collection('emails')
        .where('to', isEqualTo: user!.email!)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) => Email.fromDoc(doc)).toList();
  }

  Future<void> _openEmailDetail(Email email) async {
    setState(() => _isLoading = true);
    try {
      // mark as read
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(email.id)
          .update({'isRead': true});

      // then navigate
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailDetailPage(emailId: email.id),
        ),
      );
      // and refresh on return
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi mở email: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final initial = user?.displayName?.isNotEmpty == true
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Gmail'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchController.clear();
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _buildDrawerItem(Icons.inbox, 'Inbox', () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const GmailPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.star, 'Starred', () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const StarredPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.send, 'Sent', () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const SendMailPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.drafts, 'Drafts', () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const DraftPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.add, 'Compose Email', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ComposeEmailPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.delete_outline, 'Trash', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrashPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.person, 'Profile', () {
              Navigator.pop(context);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const AccountPage()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.refresh, 'Refresh', () {
              Navigator.pop(context);
              _loadEmails();
            }),
            const Divider(),
            _buildDrawerItem(Icons.logout, 'Logout', () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(ctx);
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomePage()),
                              (_) => false);
                        },
                        child: const Text('Logout')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // — top row: menu button / optional search / avatar —
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                  const SizedBox(width: 8),
                  if (_showSearch) ...[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search Mail',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildProfileAvatar(),
                ],
              ),
            ),

            // — email list —
            Expanded(
              child: FutureBuilder<List<Email>>(
                future: _emailsFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting ||
                      _isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError || _hasError) {
                    final msg = snap.error?.toString() ?? _errorMessage;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Có lỗi xảy ra: $msg',
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _loadEmails,
                              child: const Text('Thử lại')),
                        ],
                      ),
                    );
                  }

                  // filter by search query
                  final all = snap.data ?? [];
                  final emails = _searchQuery.isEmpty
                      ? all
                      : all.where((e) {
                          return e.subject
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              e.from.toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (emails.isEmpty) {
                    return const Center(child: Text('Không có email.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadEmails(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: emails.length,
                      itemBuilder: (context, i) {
                        final email = emails[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            child: Text(
                              email.from.isNotEmpty
                                  ? email.from[0].toUpperCase()
                                  : '?',
                            ),
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
                                  await FirebaseFirestore.instance
                                      .collection('emails')
                                      .doc(email.id)
                                      .update({'isStarred': !email.isStarred});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(email.isStarred
                                            ? 'Đã bỏ Star'
                                            : 'Đã đánh dấu Star'),
                                        duration:
                                            const Duration(milliseconds: 800),
                                      ),
                                    );
                                    _loadEmails();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('emails')
                                      .doc(email.id)
                                      .update({'isDeleted': true});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Đã chuyển email vào Thùng Rác')),
                                    );
                                    _loadEmails();
                                  }
                                },
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
        tooltip: 'Compose',
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.red),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
        ),
      ),
    );
  }
}
