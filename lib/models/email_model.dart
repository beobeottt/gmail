// lib/models/email_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Email tương ứng với cấu trúc document trong Firestore:
/// {
///   from: string,
///   to: string,
///   subject: string,
///   body: string,
///   date: Timestamp,
///   time: string,
///   isRead: bool,
///   isStarred: bool
/// }
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
  });

  /// Factory constructor để khởi tạo từ DocumentSnapshot
  factory Email.fromDoc(DocumentSnapshot doc) {
    // Ép kiểu an toàn cho Timestamp → DateTime

    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? ts = data['date'] as Timestamp?;
    final DateTime parsedDate =
        ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

    return Email(
      id: doc.id,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      date: parsedDate,
      time: data['time'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      isStarred: data['isStarred'] as bool? ?? false,
    );
  }

  /// Nếu cần chuyển Email thành Map để lưu lên Firestore
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
    };
  }
}
