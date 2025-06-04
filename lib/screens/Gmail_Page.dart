import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/email_model.dart';
import 'Compose_Email_Page.dart';
import 'Account_Page.dart';
import 'package:khoates/widgets/email_title.dart';
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

  /// Lấy tất cả email có 'to' == user.email, sắp xếp theo 'date' giảm dần.
  Future<List<Email>> fetchEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];
    final me = user.email!;

    final snapshot = await FirebaseFirestore.instance
        .collection('emails')
        .where('to', isEqualTo: me)
        .where('isDeleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => Email.fromDoc(doc)).toList();
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

      // AppBar với nút Back và tiêu đề
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gmail'),
      ),

      // Drawer menu
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

            // Inbox (trang hiện tại)
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

            // Starred
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

            // Sent
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

            // Drafts
            ListTile(
              leading: const Icon(Icons.drafts),
              title: const Text('Bản nháp'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftPage()),
                );
              },
            ),
            const Divider(),

            // Compose Email
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
            // Profile
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

            // Refresh
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                setState(() {}); // Reload lại FutureBuilder
              },
            ),
            const Divider(),

            // Logout
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

      // Body: Search bar + danh sách email
      body: SafeArea(
        child: Column(
          children: [
            // Search bar + avatar
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

            // Danh sách email
            Expanded(
              child: FutureBuilder<List<Email>>(
                future: fetchEmails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final emails = snapshot.data ?? [];
                  if (emails.isEmpty) {
                    return const Center(child: Text('Không có email nào.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: emails.length,
                    itemBuilder: (context, i) {
                      final email = emails[i];
                      return _emailTile(email);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Nút Compose
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

  /// Widget ListTile đại diện cho một email trong GmailPage
  Widget _emailTile(Email email) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        child: Text(email.from.isNotEmpty ? email.from[0].toUpperCase() : '?'),
      ),
      title: Text(
        email.subject,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: email.isRead ? Colors.grey : Colors.black,
        ),
      ),
      subtitle: Text(email.from),
      trailing: IconButton(
        icon: Icon(
          email.isStarred ? Icons.star : Icons.star_border,
          color: email.isStarred ? Colors.orange : Colors.grey,
        ),
        onPressed: () async {
          try {
            // Cập nhật giá trị isStarred (toggle)
            await FirebaseFirestore.instance
                .collection('emails')
                .doc(email.id)
                .update({'isStarred': !email.isStarred});
            // Đánh dấu đã xong, refresh lại giao diện
            setState(() {});
          } catch (e) {
            debugPrint('Error updating isStarred: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể cập nhật Starred: $e')),
            );
          }
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmailDetailPage(emailId: email.id)),
        ).then((_) {
          setState(() {});
        });
      },
    );
  }
}
