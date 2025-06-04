// lib/models/trash_email_model.dart

class TrashEmail {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final String time;
  final bool isRead;
  final bool isStarred;
  final List<dynamic> attachments; // danh sách attachment URLs

  TrashEmail({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.attachments = const [],
  });

  /// Chuyển từ Firestore document (Map<String, dynamic>) về TrashEmail
  factory TrashEmail.fromMap(Map<String, dynamic> data, String docId) {
    return TrashEmail(
      id: docId,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      time: data['time'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      isStarred: data['isStarred'] as bool? ?? false,
      attachments: data['attachments'] as List<dynamic>? ?? [],
    );
  }

  /// Chuyển từ TrashEmail về Map để dễ restore (set vào collection emails)
  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'time': time,
      'isRead': isRead,
      'isStarred': isStarred,
      'attachments': attachments,
      // Bạn có thể thêm các trường khác nếu muốn (timestamp, v.v.)
    };
  }
}
