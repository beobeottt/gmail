class Email {
  final String subject;
  final String sender;
  final DateTime date;
  final String time;
  final bool isRead;

  Email({
    required this.subject,
    required this.sender,
    required this.date,
    required this.time,
    this.isRead = false,
  });

  Email copyWith({
    String? subject,
    String? sender,
    DateTime? date,
    String? time,
    bool? isRead,
  }) {
    return Email(
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      date: date ?? this.date,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
