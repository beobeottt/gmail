import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/draft_email_model.dart';
import 'dart:async';

class ComposeEmailPage extends StatefulWidget {
  final DraftEmail? draftEmail;

  const ComposeEmailPage({Key? key, this.draftEmail}) : super(key: key);

  @override
  State<ComposeEmailPage> createState() => _ComposeEmailPageState();
}

class _ComposeEmailPageState extends State<ComposeEmailPage> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  Timer? _autoSaveTimer;
  String? _currentDraftId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.draftEmail != null) {
      _toController.text = widget.draftEmail!.to;
      _subjectController.text = widget.draftEmail!.subject;
      _bodyController.text = widget.draftEmail!.body;
      _currentDraftId = widget.draftEmail!.id;
    }
    _setupAutoSave();
  }

  void _setupAutoSave() {
    // Auto-save every 30 seconds if there are changes
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasChanges) {
        _saveDraft(isAutoSaved: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft({bool isAutoSaved = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final draft = DraftEmail(
      id: _currentDraftId ?? '',
      from: user!.email!,
      to: _toController.text.trim(),
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
      lastModified: DateTime.now(),
      isAutoSaved: isAutoSaved,
    );

    try {
      if (_currentDraftId == null) {
        // Create new draft
        final docRef = await FirebaseFirestore.instance
            .collection('drafts')
            .add(draft.toMap());
        _currentDraftId = docRef.id;
      } else {
        // Update existing draft
        await FirebaseFirestore.instance
            .collection('drafts')
            .doc(_currentDraftId)
            .update(draft.toMap());
      }
      _hasChanges = false;
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    final from = FirebaseAuth.instance.currentUser?.email;

    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }
    if (from == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn phải đăng nhập để gửi email")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Save as sent email
      final docRef = FirebaseFirestore.instance.collection('emails').doc();
      await docRef.set({
        'id': docRef.id,
        'from': from,
        'to': to,
        'subject': subject,
        'body': body,
        'date': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
        'isRead': true,
        'isStarred': false,
        'isSent': true,
        'icon': 'send',
      });

      // Delete draft if exists
      if (_currentDraftId != null) {
        await FirebaseFirestore.instance
            .collection('drafts')
            .doc(_currentDraftId)
            .delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email đã được gửi thành công")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi gửi email: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _onTextChanged() {
    _hasChanges = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_hasChanges) {
              final shouldSave = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Lưu bản nháp?'),
                      content: const Text(
                        'Bạn có muốn lưu bản nháp này không?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Không lưu'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Lưu'),
                        ),
                      ],
                    ),
              );

              if (shouldSave == true) {
                await _saveDraft();
              }
            }
            if (mounted) Navigator.pop(context);
          },
        ),
        title: const Text("Soạn Email"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveDraft(),
            tooltip: 'Lưu bản nháp',
          ),
          IconButton(
            icon:
                _isSending
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendEmail,
            tooltip: 'Gửi email',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: "Đến",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _onTextChanged(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Chủ đề",
                prefixIcon: Icon(Icons.subject),
              ),
              onChanged: (_) => _onTextChanged(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: "Nội dung",
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                maxLines: null,
                expands: true,
                onChanged: (_) => _onTextChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
