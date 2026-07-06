/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loginscreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      onTap: () {},
    );
  }

  Widget drawerLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 18, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NIA MediCare HMS"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        // Logout Icon Right Side
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      // Drawer
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                   DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.blue),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                "assets/logo/logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HOSTEL ADMIN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "MANAGEMENT SYSTEM",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        

                        

                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Text(
                                "AD",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(width: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Admin",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Super Admin",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  drawerLabel("Main Operations"),
                  drawerItem(Icons.dashboard, "Dashboard"),
                  drawerItem(Icons.check_box_outlined, "Live Attendance"),

                  drawerLabel("Admission Module"),
                  drawerItem(Icons.person_add_alt_1, "Registration Requests"),
                  drawerItem(Icons.groups, "All Residents"),

                  drawerLabel("Hostel Management"),
                  drawerItem(Icons.hotel, "Rooms & Inventory"),
                  drawerItem(Icons.verified_user_outlined, "Visitor Approvals"),

                  drawerLabel("Accounts & Support"),
                  drawerItem(Icons.currency_rupee, "Fee Collection"),
                  drawerItem(Icons.support_agent, "Complaints & Help"),
                  

                  drawerLabel("Accounts & Support"),
                  drawerItem(Icons.campaign, "Announcement"),

                  drawerLabel("Settings"),
                  drawerItem(Icons.people, "User Management"),
                  drawerItem(Icons.settings, "Roles & Permissions"),
                ],
              ),
            ),

            const Divider(height: 1),

            

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: const Center(
        child: Text(
          "Welcome to NIA MediCare HMS",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}*/
