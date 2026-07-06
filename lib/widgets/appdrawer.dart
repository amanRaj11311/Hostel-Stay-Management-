import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/loginscreen.dart';

import '../screens/dashboardscreen.dart';
import '../screens/liveattendancescreen.dart';
import '../screens/registrationreqestsscreen.dart';
import '../screens/allresidentsscreen.dart';
import '../screens/rooms&inventoryscreen.dart';
import '../screens/visitorapprovalsscreen.dart';
import '../screens/feescollectionscreen.dart';
import '../screens/complaints&helpscreen.dart';
import '../screens/announcementscreen.dart';
import '../screens/usermanagementscreen.dart';
import '../screens/roles&permissionsscreens.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String userName = "";
  String userRole = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  setState(() {
    userName = prefs.getString("userName") ?? "";
    userRole = prefs.getString("userRole") ?? "";
  });
}

  String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    List<String> words = name.trim().split(" ");

    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
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
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: Column(
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
                            child: Image.asset("assets/logo/logo.png"),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "NIA HOSTEL MANAGEMENT ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "MANAGEMENT SYSTEM",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Text(
                              getInitials(userName),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userRole,
                                style: const TextStyle(
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

                drawerItem(
                  context,
                  Icons.dashboard,
                  "Dashboard",
                  const DashboardScreen(),
                ),

                drawerItem(
                  context,
                  Icons.check_box_outlined,
                  "Live Attendance",
                  const LiveAttendanceScreen(),
                ),

                drawerLabel("Admission Module"),

                drawerItem(
                  context,
                  Icons.person_add_alt_1,
                  "Registration Requests",
                  const RegistrationReqestsScreen(),
                ),

                drawerItem(
                  context,
                  Icons.groups,
                  "All Residents",
                  const AllresidentSscreen(),
                ),

                drawerLabel("Hostel Management"),

                drawerItem(
                  context,
                  Icons.hotel,
                  "Rooms & Inventory",
                  const RoomsAndInventoryscreen(),
                ),

                drawerItem(
                  context,
                  Icons.verified_user_outlined,
                  "Visitor Approvals",
                  const VisitorApprovalsScreen(),
                ),

                drawerLabel("Accounts & Support"),

                drawerItem(
                  context,
                  Icons.currency_rupee,
                  "Fee Collection",
                  const FeesCollectionScreen(),
                ),

                drawerItem(
                  context,
                  Icons.support_agent,
                  "Complaints & Help",
                  const ComplaintsAndHelpscreen(),
                ),

                drawerItem(
                  context,
                  Icons.campaign,
                  "Announcement",
                  const AnnouncementScreen(),
                ),

                drawerLabel("Settings"),

                drawerItem(
                  context,
                  Icons.people,
                  "User Management",
                  const UsermanAgementScreen(),
                ),

                drawerItem(
                  context,
                  Icons.settings,
                  "Roles & Permissions",
                  const RolesAndPermissionsScreens(),
                ),
              ],
            ),
          ),

          const Divider(),

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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
