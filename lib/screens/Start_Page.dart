import 'package:flutter/material.dart';
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
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text(
                'Demo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              SizedBox(height: 10),
              Text(
                'Leon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ],
            
          ),

          
        ),
      ),
    );
  }
}
