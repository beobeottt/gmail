import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoates/screens/Compose_Email_Page.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Gmail_Page.dart' show GmailPage;
import 'package:khoates/screens/Home_Page.dart' show HomePage;
import 'package:khoates/screens/Send_mail.dart';
import 'package:khoates/screens/Starred_Page.dart';

class SendMailPage extends StatefulWidget {
  const SendMailPage({Key? key}) : super(key: key);

  @override
  State<SendMailPage> createState() => _SendMailPageState();
}

class _SendMailPageState extends State<SendMailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Fetch only emails sent by the current user
  Future<List<EmailModel>> fetchSentEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];
    final me = user.email!;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('emails')
            .where('from', isEqualTo: me)
            .get();

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
              leading: const Icon(Icons.add),
              title: const Text('Compose Email'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
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
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
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
      appBar: AppBar(
        title: const Text('Sent'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<EmailModel>>(
        future: fetchSentEmails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error: \${snapshot.error}'));
          }
          final emails = snapshot.data ?? [];
          if (emails.isEmpty) {
            return const Center(child: Text('No sent emails.'));
          }
          return ListView.builder(
            itemCount: emails.length,
            itemBuilder: (context, i) {
              final item = emails[i];
              return _normalItem(item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComposeEmailPage()),
            ),
        tooltip: 'Compose',
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.red),
      ),
    );
  }

  Widget _normalItem(EmailModel item) {
    return ListTile(
      leading: item.icon,
      title: Text(
        item.subject,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(item.body),
      trailing: Text(item.time),
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
