import 'dashboardscreen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'loginscreen.dart';

// अगर HomeScreen बनाया है तो इसे रखें

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      checkLogin();
    });
  }

  void checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isLogin = prefs.getBool("isLogin") ?? false;

    if (isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              height: 90,
              width: 90,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo/logo.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "NIA MediCare HMS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Patients • Doctors • Appointments • Billing • Pharmacy",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 50),

            Container(
              height: 30,
              width: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Text(
                "Hospital Management App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.white24,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Powered by NIA Smart Healthcare ERP",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}