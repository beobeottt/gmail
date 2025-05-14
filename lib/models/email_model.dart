class Email {
  final String subject;
  final String sender;
  final String snippet;
  final DateTime date;
  final String time;
  final bool isRead;

  Email({
    required this.subject,
    required this.sender,
    required this.snippet,
    required this.date,
    required this.time,
    this.isRead = false,
  });

  Email copyWith({
    String? subject,
    String? sender,
    String? snippet,
    DateTime? date,
    String? time,
    bool? isRead,
  }) {
    return Email(
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      snippet: snippet ?? this.snippet,
      date: date ?? this.date,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
