import 'package:flutter/material.dart';
import '../api/dashboard_service.dart';
import '../widgets/mainlayout.dart';

import 'liveattendancescreen.dart';
import 'visitorapprovalsscreen.dart';
import 'announcementscreen.dart';
import 'responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pull_to_refresh.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> permissions = [];

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  Map<String, dynamic>? dashboardData;
  List recentAttendance = [];
  List recentVisitors = [];
  List recentAnnouncements = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadPermissions();
    loadDashboard();
  }

  Future<void> loadPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      permissions = prefs.getStringList("permissions") ?? [];
    });

    print(permissions);
  }

  Future<void> loadDashboard() async {
    final stats = await DashboardService.getDashboardStats();
    final attendance = await DashboardService.getRecentAttendance();
    final visitors = await DashboardService.getRecentVisitors();
    final announcements = await DashboardService.getRecentAnnouncements();

    setState(() {
      dashboardData = stats["data"];
      recentAttendance = attendance["data"];
      recentVisitors = visitors["data"];
      recentAnnouncements = announcements["data"];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Dashboard",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    if (hasPermission("manage_dashboard")) ...[
                      /// Top Cards
                      Row(
                        children: [
                          Expanded(
                            child: dashboardCard(
                              "TOTAL STUDENTS",
                              dashboardData!["totalResidents"].toString(),
                              Icons.groups,
                              Colors.blue,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: dashboardCard(
                              "VACANT ROOMS",
                              dashboardData!["availableRooms"].toString(),
                              Icons.hotel,
                              Colors.indigo,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: dashboardCard(
                              "PENDING COMPLAINTS",
                              dashboardData!["pendingComplaints"].toString(),
                              Icons.refresh,
                              Colors.red,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: dashboardCard(
                              "TODAY VISITORS",
                              dashboardData!["todayVisitors"].toString(),
                              Icons.people,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),

                      if (hasPermission("manage_attendance")) ...[
                        const SizedBox(height: 25),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Attendance",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Student attendance overview",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LiveAttendanceScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("View All"),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(label: Text("NAME")),
                                    DataColumn(label: Text("ROOM")),
                                    DataColumn(label: Text("CHECK IN")),
                                    DataColumn(label: Text("CHECK OUT")),
                                    DataColumn(label: Text("STATUS")),
                                  ],
                                  rows: recentAttendance.map<DataRow>((item) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(item["studentName"] ?? ""),
                                        ),
                                        DataCell(Text(item["roomNo"] ?? "")),
                                        DataCell(
                                          Text(
                                            item["checkIn"] == null
                                                ? "--"
                                                : item["checkIn"]
                                                      .toString()
                                                      .substring(11, 16),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            item["checkOut"] == null
                                                ? "--"
                                                : item["checkOut"]
                                                      .toString()
                                                      .substring(11, 16),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item["status"] == "present"
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              item["status"],
                                              style: TextStyle(
                                                color:
                                                    item["status"] == "present"
                                                    ? Colors.green
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (hasPermission("manage_visitors")) ...[
                        const SizedBox(height: 25),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Recent Visitors",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VisitorApprovalsScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "View All",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentVisitors.length,
                                itemBuilder: (context, index) {
                                  final visitor = recentVisitors[index];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange.shade100,
                                      child: Text(
                                        visitor["visitorName"][0],
                                        style: const TextStyle(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),

                                    title: Text(visitor["visitorName"]),

                                    subtitle: Text(
                                      "${visitor["studentName"]} • Room ${visitor["roomNo"]}",
                                    ),

                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: visitor["status"] == "approved"
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        visitor["status"],
                                        style: TextStyle(
                                          color: visitor["status"] == "approved"
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (hasPermission("manage_announcements")) ...[
                        const SizedBox(height: 25),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Recent Announcements",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Latest hostel announcements",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AnnouncementScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "View All",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentAnnouncements.length,
                                itemBuilder: (context, index) {
                                  final item = recentAnnouncements[index];

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: const Icon(
                                          Icons.campaign,
                                          color: Colors.blue,
                                        ),
                                      ),

                                      title: Text(
                                        item["title"] ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 5),

                                          Text(item["message"] ?? ""),

                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              Chip(
                                                label: Text(
                                                  item["category"] ?? "",
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Chip(
                                                label: Text(
                                                  item["priority"] ?? "",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      trailing: Icon(
                                        item["isActive"] == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: item["isActive"] == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
  //dashboardCard

  Widget dashboardCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(height: 18),

            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
