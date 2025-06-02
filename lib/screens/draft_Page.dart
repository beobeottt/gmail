import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/draft_email_model.dart';
import 'Compose_Email_Page.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({Key? key}) : super(key: key);

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  Future<List<DraftEmail>> fetchDrafts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];
    final me = user.email!;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('drafts')
            .where('from', isEqualTo: me)
            .orderBy('lastModified', descending: true)
            .get();

    return snapshot.docs.map((doc) => DraftEmail.fromDoc(doc)).toList();
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await FirebaseFirestore.instance
          .collection('drafts')
          .doc(draftId)
          .delete();
      setState(() {}); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa bản nháp')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa bản nháp: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản nháp'), centerTitle: true),
      body: FutureBuilder<List<DraftEmail>>(
        future: fetchDrafts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('Không có bản nháp nào'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Dismissible(
                key: Key(draft.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => deleteDraft(draft.id),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      draft.to.isNotEmpty ? draft.to[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(
                    draft.subject.isEmpty
                        ? '(Không có tiêu đề)'
                        : draft.subject,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.to.isEmpty
                            ? '(Chưa có người nhận)'
                            : 'Đến: ${draft.to}',
                      ),
                      Text(
                        'Lần sửa cuối: ${draft.lastModified.toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: draft.isAutoSaved ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ComposeEmailPage(draftEmail: draft),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
