import 'package:flutter/material.dart';
import 'Pages/Login&Register.dart'; // Import your Login&Register page

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(), // Set LoginPage as the initial screen
    );
  }
}
