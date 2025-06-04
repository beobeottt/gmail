import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:khoates/screens/Account_Page.dart';
import 'package:khoates/screens/Compose_Email_Page.dart';
import 'package:khoates/screens/Gmail_Page.dart';
import 'package:khoates/screens/Home_Page.dart';
import 'package:khoates/screens/Start_Page.dart';
import 'package:get/get.dart';
import 'package:khoates/screens/login_page.dart' show LoginPage;
import 'firebase_options.dart';
import 'package:khoates/screens/Verification_Code.dart' show VerifyOtpPage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: StartPage());
  }
}
