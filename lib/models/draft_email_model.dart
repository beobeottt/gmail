import 'package:cloud_firestore/cloud_firestore.dart';

class DraftEmail {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime lastModified;
  final bool isAutoSaved;

  DraftEmail({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.lastModified,
    this.isAutoSaved = false,
  });

  factory DraftEmail.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp? ts = data['lastModified'] as Timestamp?;
    final DateTime lastModified = ts?.toDate() ?? DateTime.now();

    return DraftEmail(
      id: doc.id,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      lastModified: lastModified,
      isAutoSaved: data['isAutoSaved'] as bool? ?? false,
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
    };
  }

  DraftEmail copyWith({
    String? id,
    String? from,
    String? to,
    String? subject,
    String? body,
    DateTime? lastModified,
    bool? isAutoSaved,
  }) {
    return DraftEmail(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      lastModified: lastModified ?? this.lastModified,
      isAutoSaved: isAutoSaved ?? this.isAutoSaved,
    );
  }
}
