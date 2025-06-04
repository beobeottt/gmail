// lib/models/email_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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

class Email {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime date; // ngày gửi (nếu Firestore null, dùng DateTime.now())
  final String time; // trường time (chuỗi ISO hoặc do bạn set)
  final bool isRead;
  final bool isStarred;
  final bool isDeleted;
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
    this.attachments = const [],
  });

  /// Khi đọc từ Firestore, nếu data['date'] == null, sẽ dùng DateTime.now().
  factory Email.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. Xử lý attachments (nếu có)
    final rawAtts = data['attachments'] as List<dynamic>? ?? [];
    final atts = rawAtts
        .map((e) => Attachment.fromMap(e as Map<String, dynamic>))
        .toList();

    // 2. Xử lý date: nếu null, dùng DateTime.now() (hoặc bạn có thể chọn một giá trị khác)
    DateTime parsedDate;
    if (data['date'] != null && data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    // 3. Xử lý time: nếu null, cho rỗng hoặc format lại từ parsedDate
    String parsedTime;
    if (data['time'] != null && data['time'] is String) {
      parsedTime = data['time'] as String;
    } else {
      // Ví dụ: lấy giờ:phút từ parsedDate
      parsedTime = '${parsedDate.hour.toString().padLeft(2, '0')}:'
          '${parsedDate.minute.toString().padLeft(2, '0')}';
    }

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
      'attachments': attachments.map((e) => e.toMap()).toList(),
    };
  }
}
