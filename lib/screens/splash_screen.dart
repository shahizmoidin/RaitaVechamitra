import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raitavechamitra/screens/home_screen.dart';
import 'package:raitavechamitra/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Check if the user is signed in
    final user = FirebaseAuth.instance.currentUser;

    // Delay to show splash screen
    await Future.delayed(Duration(seconds: 3));

    // Navigate to the appropriate screen based on user authentication status
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[400],
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 150, height: 150),
      ),
    );
  }
}
