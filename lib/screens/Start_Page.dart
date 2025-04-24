import 'package:flutter/material.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Setting_Page.dart' show SettingPage;
import 'Home_Page.dart';
import 'login_page.dart';
import 'Register_Page.dart';
import 'package:khoates/firebase_options.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    const LoginPage(),
    const RegisterPage(),
    const HomePage(),
    const AccountPage(),
    const SettingPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leon'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: _pages,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text("Welcome to Leon App"),
          const Text("Explore our features"),
          const Text("Start your journey now!"),
          ElevatedButton(
            onPressed: () {
              // Thêm hành động khi nhấn nút
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Button pressed!")));
            },
            child: const Text("Get Started"),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Register',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
