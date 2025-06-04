// lib/models/email_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lớp Attachment giữ thông tin mỗi file đính kèm.
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
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? '',
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

/// Model Email, bao gồm cả cc, bcc và danh sách attachments.
class Email {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime date;
  final String time;
  final bool isRead;
  final bool isStarred;
  final bool isDeleted;
  final List<String> cc;
  final List<String> bcc;
  final List<Attachment> attachments;

  Email({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.date,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.cc = const [],
    this.bcc = const [],
    this.attachments = const [],
  });

  /// Chuyển từ DocumentSnapshot thành Email
  factory Email.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 1) Map attachments: list of map -> List<Attachment>
    final rawAtts = data['attachments'] as List<dynamic>? ?? [];
    final atts = rawAtts.map((e) {
      return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
    }).toList();

    // 2) Xử lý field date (Timestamp -> DateTime)
    DateTime parsedDate;
    if (data['date'] != null && data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    // 3) Xử lý field time (String)
    String parsedTime = '';
    if (data['time'] != null && data['time'] is String) {
      parsedTime = data['time'] as String;
    } else {
      // Nếu không có, dùng giờ:phút từ parsedDate
      parsedTime =
          '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
    }

    // 4) Xử lý cc và bcc (lưu dưới dạng List<dynamic> trong Firestore)
    final rawCc = data['cc'] as List<dynamic>? ?? [];
    final rawBcc = data['bcc'] as List<dynamic>? ?? [];
    final ccList = rawCc.map((e) => e as String).toList();
    final bccList = rawBcc.map((e) => e as String).toList();

    return Email(
      id: doc.id,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      date: parsedDate,
      time: parsedTime,
      isRead: data['isRead'] as bool? ?? false,
      isStarred: data['isStarred'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      cc: ccList,
      bcc: bccList,
      attachments: atts,
    );
  }

  Email copyWith({
    String? id,
    String? from,
    String? to,
    String? subject,
    String? body,
    DateTime? date,
    String? time,
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
    List<String>? cc,
    List<String>? bcc,
    List<Attachment>? attachments,
  }) {
    return Email(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      date: date ?? this.date,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'date': Timestamp.fromDate(date),
      'time': time,
      'isRead': isRead,
      'isStarred': isStarred,
      'isDeleted': isDeleted,
      'cc': cc,
      'bcc': bcc,
      'attachments': attachments.map((e) => e.toMap()).toList(),
    };
  }
}
