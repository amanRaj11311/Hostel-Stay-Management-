import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/loginscreen.dart';
import 'appdrawer.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
  });

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => logout(context),
          ),
        ],
      ),

      drawer: const AppDrawer(),

      body: body,
    );
  }
}