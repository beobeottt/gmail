import 'package:flutter/material.dart';
import 'package:khoates/models/email_model.dart' show Email;

class EmailTitle extends StatelessWidget {
  final Email email;
  const EmailTitle({Key? key, required this.email}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          email.sender[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(),
    );
  }
}
