import 'package:flutter/material.dart';
import '../api/attendance_service.dart';
import '../widgets/mainlayout.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class LiveAttendanceScreen extends StatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  List attendanceList = [];
  bool isLoading = true;
  bool showSearch = false;
  String selectedStatus = "All";
  List filteredAttendance = [];

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final response = await AttendanceService.getAttendance();
    for (var item in attendanceList) {
  print(item["status"]);
}

    setState(() {
      attendanceList = response["data"] ?? [];
      filteredAttendance = attendanceList;
      isLoading = false;
    });
  }

  void applyFilters() {
    setState(() {
      filteredAttendance = attendanceList.where((item) {
        if (selectedStatus == "All") {
          return true;
        }

        return item["status"] == selectedStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Live Attendance",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadAttendance,

              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.w * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                "Attendance Log",
                                style: TextStyle(
                                  fontSize: context.w * 0.06,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.login),
                              label: const Text("Manual Check In"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w * 0.04,
                                  vertical: context.h * 0.015,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Track student entry and exit logs in real-time.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// Search + Filter
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!showSearch)
                            Row(
                              children: [
                                const Spacer(),

                                IconButton(
                                  icon: const Icon(Icons.search, size: 28),
                                  onPressed: () {
                                    setState(() {
                                      showSearch = true;
                                    });
                                  },
                                ),

                                const SizedBox(width: 15),

                                SizedBox(
                                  width: 180,
                                  child: attendanceDropdown(),
                                ),
                              ],
                            ),

                          if (showSearch) ...[
                            TextField(
                              decoration: InputDecoration(
                                hintText: "Search Student",
                                prefixIcon: const Icon(Icons.search),

                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      showSearch = false;
                                    });
                                  },
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            SizedBox(
                              width: double.infinity,
                              child: attendanceDropdown(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Table
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAttendance.length,
                      itemBuilder: (context, index) {
                        final item = filteredAttendance[index];

                        final isPresent = item["status"] == "present";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(context.w * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Student Name
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.indigo.shade100,
                                      child: const Icon(Icons.person),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item["studentName"] ?? "",
                                        style: TextStyle(
                                          fontSize: context.w * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPresent ? "Inside" : "Outside",
                                        style: TextStyle(
                                          color: isPresent
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        Icons.meeting_room,
                                        "Room",
                                        item["roomNo"] ?? "",
                                      ),
                                    ),
                                    Expanded(
                                      child: _infoTile(
                                        Icons.calendar_today,
                                        "Date",
                                        item["date"].toString().substring(
                                          0,
                                          10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        Icons.login,
                                        "Check In",
                                        item["checkIn"] == null
                                            ? "--"
                                            : item["checkIn"]
                                                  .toString()
                                                  .substring(11, 16),
                                      ),
                                    ),
                                    Expanded(
                                      child: _infoTile(
                                        Icons.logout,
                                        "Check Out",
                                        item["checkOut"] == null
                                            ? "--"
                                            : item["checkOut"]
                                                  .toString()
                                                  .substring(11, 16),
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 25),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isPresent)
                                      ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.logout),
                                        label: const Text("Checkout"),
                                      ),

                                    const SizedBox(width: 10),

                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ), // yha per lagana hai
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget attendanceDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: "All", child: Text("All")),
        DropdownMenuItem(value: "present", child: Text("Inside")),
        DropdownMenuItem(value: "checkedout", child: Text("Outside")),
      ],
      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
        applyFilters();
      },
    );
  }
}
