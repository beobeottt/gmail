// lib/models/draft_email_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lớp Attachment dùng cho bản nháp
class Attachment {
  final String name;
  final String url;
  final String type;

  Attachment({
    required this.name,
    required this.url,
    required this.type,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
    };
  }
}

/// Model cho một bản nháp email
class DraftEmail {
  final String id; // Nếu mới chưa lưu thì id = ''
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime lastModified;
  final bool isAutoSaved;
  final List<Attachment> attachments;

  DraftEmail({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.lastModified,
    required this.isAutoSaved,
    this.attachments = const [],
  });

  factory DraftEmail.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAtts = data['attachments'] as List<dynamic>? ?? [];
    final atts = rawAtts
        .map((e) => Attachment.fromMap(e as Map<String, dynamic>))
        .toList();

    return DraftEmail(
      id: doc.id,
      from: data['from'] as String,
      to: data['to'] as String,
      subject: data['subject'] as String,
      body: data['body'] as String,
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      isAutoSaved: data['isAutoSaved'] as bool? ?? false,
      attachments: atts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'lastModified': Timestamp.fromDate(lastModified),
      'isAutoSaved': isAutoSaved,
      'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }
}
