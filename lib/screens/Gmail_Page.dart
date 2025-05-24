import 'package:flutter/material.dart';
import 'package:khoates/screens/Compose_Email_Page.dart';

class GmailPage extends StatefulWidget {
  //final String title;

  const GmailPage({Key? key}) : super(key: key);

  @override
  State<GmailPage> createState() => _GmailPageState();
}

class _GmailPageState extends State<GmailPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: 16),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              title: Material(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: "Search Mail",
                      border: InputBorder.none,
                      icon: Icon(Icons.dehaze_outlined),
                      suffixIcon: Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: CircleAvatar(
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                List.generate(getEmailList().length, (index) {
                  final item = getEmailList()[index];
                  return item.isTopItem ? _topItem(item) : _normalItem(item);
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ComposeEmailPage()),
          );
        },
        tooltip: 'Increment',
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.red),
      ),
    );
  }

  List<EmailModel> getEmailList() {
    return [
      EmailModel(
        Icon(Icons.people_outline_rounded, color: Colors.blue),
        "Social",
        "Youtube",
        "null",
        "null",
        true,
      ),
      EmailModel(
        Icon(Icons.tag, color: Colors.green),
        "Promotions",
        "Think with Google",
        "null",
        "null",
        true,
      ),
      EmailModel(
        Icon(Icons.forum_outlined, color: Colors.purple),
        "Forum",
        "Google Play",
        "null",
        "null",
        true,
      ),
      EmailModel(
        Icon(Icons.person_outline, color: Colors.white),
        "Email subject",
        "Please subscribe to our channel!!",
        "Name",
        "10:00 AM",
        false,
      ),
      // Add more items if needed
    ];
  }

  Widget _topItem(EmailModel item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      tileColor: Colors.white,
      leading: item.icon,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.subject, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(item.body, style: TextStyle(color: Colors.grey)),
        ],
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: item.icon.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "12 new",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _normalItem(EmailModel item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      tileColor: Colors.white,
      leading: CircleAvatar(backgroundColor: Colors.red, child: item.icon),
      title: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.from,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isRead ? Colors.grey : Colors.black,
                  ),
                ),
                Text(
                  item.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isRead ? Colors.grey : Colors.black,
                  ),
                ),
              ],
            ),
            Text(
              item.subject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isRead ? Colors.grey : Colors.black,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.body,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Icon(Icons.star_border_outlined, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmailModel {
  final Icon icon;
  final String subject;
  final String body;
  final String from;
  final String time;
  final bool isTopItem;
  final bool isRead;

  EmailModel(
    this.icon,
    this.subject,
    this.body,
    this.from,
    this.time,
    this.isTopItem, [
    this.isRead = false,
  ]);
}
