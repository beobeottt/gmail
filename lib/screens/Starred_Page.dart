import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoates/screens/Compose_Email_Page.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Gmail_Page.dart' show GmailPage;
import 'package:khoates/screens/Send_mail.dart';
import 'package:khoates/screens/Starred_Page.dart';

import 'Home_Page.dart';

class StarredPage extends StatefulWidget {
  const StarredPage({Key? key}) : super(key: key);

  @override
  State<StarredPage> createState() => _StarredPageState();
}

class _StarredPageState extends State<StarredPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<EmailModel>> fetchEmails() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('emails').get();
    return snapshot.docs.map((doc) => EmailModel.fromMap(doc.data())).toList();
  }

  Widget _buildProfileAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.photoURL != null) {
      return GestureDetector(
        onTap:
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
        child: CircleAvatar(backgroundImage: NetworkImage(user.photoURL!)),
      );
    } else if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return GestureDetector(
        onTap:
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
        child: CircleAvatar(
          child: Text(user.displayName!.substring(0, 1).toUpperCase()),
        ),
      );
    } else {
      return GestureDetector(
        onTap:
            () => Navigator.pushReplacement(
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
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Inbox'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => GmailPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => StarredPage()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SendMailPage()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Compose Email'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ComposeEmailPage()),
                );
              },
            ),

            const Divider(),
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
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Gmail'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('LogOut'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('confirm Logout'),
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
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button at top
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Bottom row: hamburger, search bar, avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed:
                              () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Expanded(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: TextField(
                                decoration: const InputDecoration(
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
          SliverToBoxAdapter(
            child: FutureBuilder<List<EmailModel>>(
              future: fetchEmails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }

                final emails = snapshot.data ?? [];
                return Column(
                  children:
                      emails.map((item) {
                        return item.isTopItem
                            ? _topItem(item)
                            : _normalItem(item);
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComposeEmailPage()),
            ),
        tooltip: 'Compose',
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.red),
      ),
    );
  }

  Widget _topItem(EmailModel item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      tileColor: Colors.white,
      leading: item.icon,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.subject,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(item.body, style: const TextStyle(color: Colors.grey)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: item.icon.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "12 new",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _normalItem(EmailModel item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      tileColor: Colors.white,
      leading: CircleAvatar(backgroundColor: Colors.red, child: item.icon),
      title: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.from,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isRead ? Colors.grey : Colors.black,
                  ),
                ),
                Text(
                  item.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isRead ? Colors.grey : Colors.black,
                  ),
                ),
              ],
            ),
            Text(
              item.subject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isRead ? Colors.grey : Colors.black,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.body,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const Icon(Icons.star_border_outlined, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmailModel {
  final Icon icon;
  final String subject;
  final String body;
  final String from;
  final String time;
  final bool isTopItem;
  final bool isRead;

  EmailModel(
    this.icon,
    this.subject,
    this.body,
    this.from,
    this.time,
    this.isTopItem, [
    this.isRead = false,
  ]);

  factory EmailModel.fromMap(Map<String, dynamic> data) {
    return EmailModel(
      _getIconByName(data['icon']),
      data['subject'] ?? '',
      data['body'] ?? '',
      data['from'] ?? '',
      data['time'] ?? '',
      data['isTopItem'] ?? false,
      data['isRead'] ?? false,
    );
  }

  static Icon _getIconByName(String? name) {
    switch (name) {
      case 'people':
        return const Icon(Icons.people_outline_rounded, color: Colors.blue);
      case 'tag':
        return const Icon(Icons.tag, color: Colors.green);
      case 'forum':
        return const Icon(Icons.forum_outlined, color: Colors.purple);
      case 'person':
        return const Icon(Icons.person_outline, color: Colors.white);
      default:
        return const Icon(Icons.email, color: Colors.grey);
    }
  }
}
