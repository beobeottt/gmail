// lib/screens/compose_email_page.dart

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

// Giữ Attachment từ draft_email_model, ẩn Attachment từ email_model để tránh trùng
import '../models/draft_email_model.dart';
import '../models/email_model.dart' hide Attachment;

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

  final List<Attachment> _attachments = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

    // Nếu có bản nháp, tiền điền
    if (widget.draftEmail != null) {
      _toController.text = widget.draftEmail!.to;
      _subjectController.text = widget.draftEmail!.subject;
      _bodyController.text = widget.draftEmail!.body;
      _currentDraftId = widget.draftEmail!.id;
      _attachments.addAll(widget.draftEmail!.attachments);
    }

    _setupAutoSave();
    _toController.addListener(_onTextChanged);
    _subjectController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  void _setupAutoSave() {
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

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần quyền truy cập thư viện ảnh để đính kèm ảnh'),
            ),
          );
        }
        return false;
      }
    } else if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần quyền truy cập bộ nhớ để đính kèm ảnh'),
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _showImageSourceDialog() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;
      if (!mounted) return;

      setState(() => _isSending = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/email_attachments/$fileName');

      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File quá lớn. Kích thước tối đa là 5MB');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải ảnh lên...'),
          duration: Duration(seconds: 1),
        ),
      );

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snap) {
        final progress = snap.bytesTransferred / snap.totalBytes * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _attachments.add(
          Attachment(
            name: image.name,
            url: downloadUrl,
            type: 'image/jpeg',
          ),
        );
        _hasChanges = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải ảnh lên thành công')),
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'Không có quyền truy cập Storage';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload bị hủy';
          break;
        case 'storage/object-not-found':
          errorMessage =
              'Không thể tạo file trong Storage. Vui lòng kiểm tra Storage bucket và quy tắc.';
          break;
        default:
          errorMessage = 'Lỗi khi tải ảnh lên: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    try {
      final attachment = _attachments[index];

      if (!attachment.url.startsWith('https://')) {
        throw Exception('URL không hợp lệ');
      }

      final ref = FirebaseStorage.instance.refFromURL(attachment.url);

      try {
        await ref.getMetadata();
      } on FirebaseException catch (e) {
        if (e.code == 'storage/object-not-found') {
          debugPrint(
              'File không tồn tại trong Storage, chỉ xóa khỏi danh sách');
          setState(() {
            _attachments.removeAt(index);
            _hasChanges = true;
          });
          return;
        }
        rethrow;
      }

      await ref.delete();

      setState(() {
        _attachments.removeAt(index);
        _hasChanges = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa file đính kèm')),
      );
    } catch (e) {
      debugPrint('Error removing attachment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa file đính kèm: $e')),
      );
    }
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
      attachments: _attachments,
    );

    try {
      if (_currentDraftId == null) {
        final docRef = await FirebaseFirestore.instance
            .collection('drafts')
            .add(draft.toMap());
        _currentDraftId = docRef.id;
      } else {
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
        'isDeleted': false,
        'attachments': _attachments.map((a) => a.toMap()).toList(),
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi gửi email: $e")),
        );
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
                builder: (context) => AlertDialog(
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
            icon: const Icon(Icons.attach_file),
            onPressed: _showImageSourceDialog,
            tooltip: 'Đính kèm ảnh',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveDraft(),
            tooltip: 'Lưu bản nháp',
          ),
          IconButton(
            icon: _isSending
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Chủ đề",
                prefixIcon: Icon(Icons.subject),
              ),
            ),
            const SizedBox(height: 12),
            if (_attachments.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                attachment.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeAttachment(index),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
