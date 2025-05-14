import 'package:flutter/material.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Setting_Page.dart' show SettingPage;
import 'package:khoates/screens/login_page.dart';
import 'Home_Page.dart';
import 'Register_Page.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = const [
    RegisterPhonePage(),
    HomePage(),
    AccountPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leon'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Our App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              "Pham Bao Long",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              "Cong Minh",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Hành động khi nhấn nút
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Button pressed!")),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text("Get Started"),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.blue,
      //   selectedItemColor: Colors.green,
      //   unselectedItemColor: Colors.black,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.app_registration),
      //       label: 'Register',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      //   ],
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      // ),
    );
  }
}
