import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/loginscreen.dart';
import '../screens/roles&permissionsscreens.dart';
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
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert), // 3 dots

      onSelected: (value) {
        if (value == "settings") {
          // Settings screen open karo
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RolesAndPermissionsScreens(),
            ),
          );
        }

        if (value == "logout") {
          logout(context);
        }
      },

      itemBuilder: (context) => [
        const PopupMenuItem(
          value: "settings",
          child: Row(
            children: [
              Icon(Icons.settings,color: Colors.blue,),
              SizedBox(width: 10),
              Text("Settings"),
              
            ],
          ),
        ),

        const PopupMenuItem(
          value: "logout",
          child: Row(
            children: [
              Icon(Icons.logout,color: Colors.blue),
              SizedBox(width: 10),
              Text("Logout"),
            ],
          ),
        ),
      ],
    ),
  ],
),

      drawer: const AppDrawer(),

      body: body,
    );
  }
}