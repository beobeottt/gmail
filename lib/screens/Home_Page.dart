import 'package:flutter/material.dart';
import 'package:khoates/screens/login_page.dart';
import 'package:khoates/screens/Register_Page.dart';
import 'package:khoates/screens/Home_Page.dart';
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  // final List<Widget> _pages = [
  //   const LoginPage(),
  //   const RegisterPage(),
  //   const HomePage(),
  // ];
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
      body: PageView(
        controller: _pageController,
        // children: _pages,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      // 2 button dưới đáy để chuyển các trang
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,

        // onTap: (index)
        // {
        //   setState(() {
        //     _selectedIndex = index;
        //   });
        // }
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Register',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
