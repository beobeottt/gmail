import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:khoates/screens/login_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leon'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Welcome to Our App",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Pham Bao Long",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  "Cong Minh",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  "Nguyen Bao",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Button pressed!")),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      "Get Started",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.blue.withOpacity(0.9),
      //   selectedItemColor: Colors.white,
      //   unselectedItemColor: Colors.white70,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.app_registration), label: 'Register'),
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
