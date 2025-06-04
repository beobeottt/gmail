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

class StarredPage extends StatefulWidget {
  const StarredPage({Key? key}) : super(key: key);

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 1) Hàm fetchEmails đưa ra danh sách Email đã được star, gán debugPrint
  /// để in log rõ ràng, giúp kiểm tra index, dữ liệu Firestore.
  Future<List<Email>> fetchEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      debugPrint('fetchEmails: user chưa login hoặc user.email == null');
      return [];
    }
    final email = user.email!;
    debugPrint('fetchEmails: user.email = $email');

    try {
      // Bước 1: Test chỉ WHERE("to", isEqualTo: email)
      final onlyToSnap = await FirebaseFirestore.instance
          .collection('emails')
          .where('to', isEqualTo: email)
          .get();
      debugPrint('  [Debug] only where(to): count = ${onlyToSnap.docs.length}');

      // Bước 2: Test thêm WHERE("isStarred", true)
      final starredSnap = await FirebaseFirestore.instance
          .collection('emails')
          .where('to', isEqualTo: email)
          .where('isStarred', isEqualTo: true)
          .get();
      debugPrint(
        '  [Debug] where(to)+where(isStarred): count = ${starredSnap.docs.length}',
      );

      // In ra data để kiểm tra (nếu có)
      for (var doc in starredSnap.docs) {
        debugPrint('    DocID=${doc.id}, data=${doc.data()}');
      }

      return starredSnap.docs.map((doc) => Email.fromDoc(doc)).toList();
    } catch (e) {
      debugPrint('fetchEmails: Lỗi khi query Firebase: $e');
      // Nếu lỗi require-index, e.toString() sẽ chứa URL gợi link tạo index
      return [];
    }
  }

  /// 2) Biểu tượng profile avatar góc trên cùng
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
            // Starred (đang ở trang này)
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context),
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
                  content: const Text(
                    'Are you sure you want to log out?',
                  ),
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
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
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
      body: CustomScrollView(
        slivers: [
          // SliverAppBar với nút back + search + avatar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nút Back
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
                  // Search + Avatar
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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

          // Nơi hiện danh sách email đã star
          SliverToBoxAdapter(
            child: FutureBuilder<List<Email>>(
              future: fetchEmails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(child: Text("error: ${snapshot.error}")),
                  );
                }

                final emails = snapshot.data ?? [];
                if (emails.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text("Bạn chưa có email nào được tim."),
                    ),
                  );
                }

                // Dùng ListView.builder trong SliverToBoxAdapter
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 180,
                  // Trừ 180 để phần SliverAppBar + padding chạy ổn
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: emails.length,
                    itemBuilder: (context, index) {
                      final item = emails[index];
                      return _emailItem(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

  /// Widget hiển thị 1 email đã star
  Widget _emailItem(Email item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: Colors.redAccent,
        child: Text(
          item.from.isNotEmpty ? item.from[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.subject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isRead ? Colors.grey : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Icon star cứng để chỉ rằng đây là email đã star
          const Icon(Icons.star, color: Colors.orange, size: 20),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.from,
              style: TextStyle(color: item.isRead ? Colors.grey : Colors.black),
            ),
            Text(
              item.time,
              style: TextStyle(color: item.isRead ? Colors.grey : Colors.black),
            ),
          ],
        ),
      ),
      onTap: () {
        // push qua Email_title_page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmailDetailPage(emailId: item.id)),
        );
      },
    );
  }
}
