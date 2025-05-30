import 'package:cloud_firestore/cloud_firestore.dart';

class Email {
  final String id;
  final String subject;
  final String sender;
  final DateTime date;
  final String time;
  final bool isRead;
  final bool isStarred;

  Email({
    required this.id,
    required this.subject,
    required this.sender,
    required this.date,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
  });

  factory Email.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? ts = data['date'] as Timestamp?;
    final DateTime parsedDate =
        ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Email(
      id: doc.id,
      subject: data['subject'] as String? ?? '',
      sender: data['from'] as String? ?? '',
      date: parsedDate,
      time: data['time'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      isStarred: data['isStarred'] as bool? ?? false,
    );
  }
}
