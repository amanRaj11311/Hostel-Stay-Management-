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
  List<String> permissions = [];

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
      permissions = prefs.getStringList("permissions") ?? [];
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

  bool hasPermission(String permission) {
    return permissions.contains(permission);
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

                if (hasPermission("manage_dashboard") ||
                    hasPermission("manage_attendance"))
                  drawerLabel("Main Operations"),

                if (hasPermission("manage_dashboard"))
                  drawerItem(
                    context,
                    Icons.dashboard,
                    "Dashboard",
                    const DashboardScreen(),
                  ),

                if (hasPermission("manage_attendance"))
                  drawerItem(
                    context,
                    Icons.check_box_outlined,
                    "Live Attendance",
                    const LiveAttendanceScreen(),
                  ),

                if (hasPermission("manage_residents"))
                  drawerLabel("Admission Module"),

                if (hasPermission("manage_residents"))
                  drawerItem(
                    context,
                    Icons.person_add_alt_1,
                    "Registration Requests",
                    const RegistrationReqestsScreen(),
                  ),
                if (hasPermission("manage_residents"))
                  drawerItem(
                    context,
                    Icons.groups,
                    "All Residents",
                    const AllresidentSscreen(),
                  ),

                if (hasPermission("manage_rooms") ||
                    hasPermission("manage_visitors"))
                  drawerLabel("Hostel Management"),

                if (hasPermission("manage_rooms"))
                  drawerItem(
                    context,
                    Icons.hotel,
                    "Rooms & Inventory",
                    const RoomsAndInventoryscreen(),
                  ),

                if (hasPermission("manage_visitors"))
                  drawerItem(
                    context,
                    Icons.verified_user_outlined,
                    "Visitor Approvals",
                    const VisitorApprovalsScreen(),
                  ),

                if (hasPermission("manage_fees") ||
                    hasPermission("manage_complaints") ||
                    hasPermission("manage_announcements"))
                  drawerLabel("Accounts & Support"),

                if (hasPermission("manage_fees"))
                  drawerItem(
                    context,
                    Icons.currency_rupee,
                    "Fee Collection",
                    const FeesCollectionScreen(),
                  ),

                if (hasPermission("manage_complaints"))
                  drawerItem(
                    context,
                    Icons.support_agent,
                    "Complaints & Help",
                    const ComplaintsAndHelpscreen(),
                  ),

                if (hasPermission("manage_announcements"))
                  drawerItem(
                    context,
                    Icons.campaign,
                    "Announcement",
                    const AnnouncementScreen(),
                  ),

                if (hasPermission("manage_users") ||
                    hasPermission("manage_roles"))
                  drawerLabel("Settings"),

                if (hasPermission("manage_users"))
                  drawerItem(
                    context,
                    Icons.people,
                    "User Management",
                    const UsermanAgementScreen(),
                  ),

                if (hasPermission("manage_roles"))
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
