import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/login_service.dart';
import 'package:location_tracker_app/view/login/login_page.dart';
import 'package:location_tracker_app/view/mainscreen/homepage.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LoginService _authService = LoginService();

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Show splash for 2-3 seconds
    await Future.delayed(Duration(seconds: 3));

    // Check login status
    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isLoggedIn ? MainScreen() : LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon.png', width: 200, height: 120),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
