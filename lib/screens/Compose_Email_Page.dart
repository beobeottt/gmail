import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_options.dart';
// Alias your draft model so its Attachment doesn’t clash
import '../models/draft_email_model.dart' as draft;
// Hide Attachment from email model
import '../models/email_model.dart' hide Attachment;

class ComposeEmailPage extends StatefulWidget {
  final draft.DraftEmail? draftEmail;
  final String? mode; // null, 'reply', 'replyAll', 'forward'
  final Email? originalEmail;

  const ComposeEmailPage({
    Key? key,
    this.draftEmail,
    this.mode,
    this.originalEmail,
  }) : super(key: key);

  @override
  State<ComposeEmailPage> createState() => _ComposeEmailPageState();
}

class _ComposeEmailPageState extends State<ComposeEmailPage> {
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isSending = false;
  Timer? _autoSaveTimer;
  String? _currentDraftId;
  bool _hasChanges = false;

  // Use draft.Attachment here
  final List<draft.Attachment> _attachments = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

    // Load existing draft if any
    if (widget.draftEmail != null) {
      final d = widget.draftEmail!;
      _toController.text = d.to;
      _ccController.text = d.cc.join(', ');
      _bccController.text = d.bcc.join(', ');
      _subjectController.text = d.subject;
      _bodyController.text = d.body;
      _currentDraftId = d.id;
      _attachments.addAll(d.attachments);
    }

    // Prepare reply / forward if requested
    if (widget.mode != null && widget.originalEmail != null) {
      final orig = widget.originalEmail!;
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      String prefix;
      if (widget.mode == 'reply' || widget.mode == 'replyAll') {
        prefix = 'Re: ';
      } else if (widget.mode == 'forward') {
        prefix = 'Fwd: ';
      } else {
        prefix = '';
      }
      final origSubj = orig.subject;
      if (origSubj.startsWith(prefix)) {
        _subjectController.text = origSubj;
      } else {
        _subjectController.text = '$prefix$origSubj';
      }
      if (widget.mode == 'reply') {
        _toController.text = orig.from;
      } else if (widget.mode == 'replyAll') {
        final recipients = <String>{};
        for (var addr in orig.to.split(',')) {
          final email = addr.trim();
          if (email.isNotEmpty && email != currentUserEmail)
            recipients.add(email);
        }
        for (var cc in orig.cc) {
          if (cc.isNotEmpty && cc != currentUserEmail) recipients.add(cc);
        }
        if (orig.from.isNotEmpty && orig.from != currentUserEmail)
          recipients.add(orig.from);
        _toController.text = recipients.join(', ');
      }
      final buffer = StringBuffer();
      buffer.writeln();
      buffer.writeln('__________________________________');
      buffer.writeln(
          'On ${orig.date.day}/${orig.date.month}/${orig.date.year} at ${orig.time}, ${orig.from} wrote:');
      for (var line in orig.body.split('\n')) buffer.writeln('> \$line');
      _bodyController.text = buffer.toString();
      _hasChanges = true;
    }

    _setupAutoSave();
    _toController.addListener(_onTextChanged);
    _ccController.addListener(_onTextChanged);
    _bccController.addListener(_onTextChanged);
    _subjectController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasChanges) _saveDraft(isAutoSaved: true);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền truy cập ảnh')),
        );
        return false;
      }
    } else {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần quyền truy cập bộ nhớ')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _showImageSourceDialog() async {
    if (!await _requestPermission()) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1024, maxHeight: 1024);
    if (image == null) return;
    setState(() => _isSending = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    final file = File(image.path);
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) throw Exception('File quá lớn');
    final ref = FirebaseStorage.instance.ref().child(
        'users/\${user.uid}/email_attachments/\${DateTime.now().millisecondsSinceEpoch}.jpg');
    final upload =
        ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    await upload.whenComplete(() {});
    final url = await ref.getDownloadURL();
    setState(() {
      _attachments.add(
          draft.Attachment(name: image.name, url: url, type: 'image/jpeg'));
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ảnh đã tải lên')));
    setState(() => _isSending = false);
  }

  Future<void> _removeAttachment(int i) async {
    final att = _attachments[i];
    final ref = FirebaseStorage.instance.refFromURL(att.url);
    await ref.delete();
    setState(() {
      _attachments.removeAt(i);
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã xóa file')));
  }

  Future<void> _saveDraft({bool isAutoSaved = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    final d = draft.DraftEmail(
      id: _currentDraftId ?? '',
      from: user!.email!,
      to: _toController.text.trim(),
      cc: _ccController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      bcc: _bccController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
      lastModified: DateTime.now(),
      isAutoSaved: isAutoSaved,
      attachments: _attachments,
    );
    final col = FirebaseFirestore.instance.collection('drafts');
    if (_currentDraftId == null) {
      final r = await col.add(d.toMap());
      _currentDraftId = r.id;
    } else {
      await col.doc(_currentDraftId).update(d.toMap());
    }
    _hasChanges = false;
  }

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final subj = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    final from = FirebaseAuth.instance.currentUser?.email;
    if (from == null || (to.isEmpty && subj.isEmpty && body.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thiếu thông tin')));
      return;
    }
    setState(() => _isSending = true);
    final doc = FirebaseFirestore.instance.collection('emails').doc();
    await doc.set({
      'id': doc.id,
      'from': from,
      'to': to,
      'cc': _ccController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'bcc': _bccController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'subject': subj,
      'body': body,
      'date': FieldValue.serverTimestamp(),
      'time': DateTime.now().toIso8601String(),
      'isRead': false,
      'isStarred': false,
      'isDeleted': false,
      'attachments': _attachments.map((a) => a.toMap()).toList(),
    });
    if (_currentDraftId != null) {
      await FirebaseFirestore.instance
          .collection('drafts')
          .doc(_currentDraftId)
          .delete();
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã gửi email')));
    Navigator.pop(context);
    setState(() => _isSending = false);
  }

  void _onTextChanged() => _hasChanges = true;

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_hasChanges) {
              final save = await showDialog<bool>(
                context: ctx,
                builder: (_) => AlertDialog(
                  title: const Text('Lưu bản nháp?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Không')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Lưu')),
                  ],
                ),
              );
              if (save == true) await _saveDraft();
            }
            Navigator.pop(ctx);
          },
        ),
        title: const Text('Soạn Email'),
        actions: [
          IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showImageSourceDialog),
          IconButton(
              icon: const Icon(Icons.save), onPressed: () => _saveDraft()),
          IconButton(
            icon: _isSending
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendEmail,
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
                    labelText: 'Đến', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextField(
                controller: _ccController,
                decoration: const InputDecoration(
                    labelText: 'Cc',
                    prefixIcon: Icon(Icons.group),
                    hintText: 'email, cách nhau bằng dấu phẩy')),
            const SizedBox(height: 12),
            TextField(
                controller: _bccController,
                decoration: const InputDecoration(
                    labelText: 'Bcc',
                    prefixIcon: Icon(Icons.lock),
                    hintText: 'email, dấu phẩy')),
            const SizedBox(height: 12),
            TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                    labelText: 'Chủ đề', prefixIcon: Icon(Icons.subject))),
            const SizedBox(height: 12),
            if (_attachments.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (c, i) {
                    final a = _attachments[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(a.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.image_not_supported))),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeAttachment(i)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.message_outlined)),
                expands: true,
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
