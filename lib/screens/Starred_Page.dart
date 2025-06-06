// lib/screens/Starred_Page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:khoates/screens/Compose_Email_Page.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Gmail_Page.dart' show GmailPage;
import 'package:khoates/screens/Send_mail.dart';
import '../models/email_model.dart';
import '../widgets/email_title.dart';
import 'Home_Page.dart';
import 'Trash_Page.dart';

class StarredPage extends StatefulWidget {
  const StarredPage({Key? key}) : super(key: key);

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Lấy danh sách email đã được đánh dấu Star
  Future<List<Email>> fetchEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      debugPrint('fetchEmails: user chưa login hoặc user.email == null');
      return [];
    }
    final email = user.email!;
    debugPrint('fetchEmails: user.email = $email');

    try {
      // Lọc email: to == currentUser && isStarred == true && isDeleted == false
      final starredSnap = await FirebaseFirestore.instance
          .collection('emails')
          .where('to', isEqualTo: email)
          .where('isStarred', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();

      debugPrint(
          '  [Debug] where(to)+where(isStarred): count = ${starredSnap.docs.length}');
      for (var doc in starredSnap.docs) {
        debugPrint('    DocID=${doc.id}, data=${doc.data()}');
      }

      return starredSnap.docs.map((doc) => Email.fromDoc(doc)).toList();
    } catch (e) {
      debugPrint('fetchEmails: Lỗi khi query Firebase: $e');
      return [];
    }
  }

  /// Xây dựng avatar (góc trên cùng bên phải)
  Widget _buildProfileAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.photoURL != null) {
      return GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        ),
        child: CircleAvatar(backgroundImage: NetworkImage(user.photoURL!)),
      );
    } else if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        ),
        child: CircleAvatar(
          child: Text(user.displayName!.substring(0, 1).toUpperCase()),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        ),
        child: const CircleAvatar(child: Icon(Icons.person_outline)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // Drawer giống GmailPage để chuyển giữa các mục
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
            // Inbox
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Inbox'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GmailPage()),
                );
              },
            ),
            const Divider(),
            // Sent
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SendMailPage()),
                );
              },
            ),
            const Divider(),
            // Compose Email
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Compose Email'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
                );
              },
            ),
            const Divider(),
            // Profile
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
              },
            ),
            const Divider(),
            // Refresh
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                setState(() {}); // gọi lại build → FutureBuilder reload
              },
            ),
            const Divider(),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
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

      // Dùng CustomScrollView + SliverAppBar để giống GmailPage
      body: CustomScrollView(
        slivers: [
          // SliverAppBar: chứa nút Back, Search, Avatar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nút Back để quay về GmailPage
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GmailPage()),
                      );
                    },
                  ),
                  // Search và Avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Expanded(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search Mail',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildProfileAvatar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Đây là phần SliverToBoxAdapter được thay đổi lại,
          // hoàn toàn giống cấu trúc của GmailPage, chỉ khác filter fetchEmails()
          SliverToBoxAdapter(
            child: FutureBuilder<List<Email>>(
              future: fetchEmails(),
              builder: (context, snapshot) {
                // Đang chờ load data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                // Báo lỗi nếu có
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(child: Text("Error: ${snapshot.error}")),
                  );
                }

                final emails = snapshot.data ?? [];
                if (emails.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text("Bạn chưa có email nào được Star."),
                    ),
                  );
                }

                // SizedBox để gán chiều cao cho ListView.builder
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 180,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: emails.length,
                    itemBuilder: (context, index) {
                      final email = emails[index];
                      // Cấu trúc ListTile giống hệt GmailPage
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
                            // Nút Star (bấm sẽ bỏ Star)
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
                                  await FirebaseFirestore.instance
                                      .collection('emails')
                                      .doc(email.id)
                                      .update({'isStarred': !email.isStarred});
                                  setState(() {}); // reload lại giao diện
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Lỗi khi cập nhật Starred: $e')),
                                    );
                                  }
                                }
                              },
                              tooltip: email.isStarred ? 'Bỏ Star' : 'Star',
                            ),
                            // Nút Trash (bấm sẽ chuyển email vào Thùng Rác)
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
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Đã chuyển email vào Thùng Rác'),
                                        duration: Duration(milliseconds: 800),
                                      ),
                                    );
                                  }
                                  setState(() {}); // reload lại danh sách
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Lỗi khi di chuyển vào Thùng Rác: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Move to Trash',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EmailDetailPage(emailId: email.id),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Nút Compose góc dưới phải
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
