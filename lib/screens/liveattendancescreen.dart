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

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final response = await AttendanceService.getAttendance();

    setState(() {
      attendanceList = response["data"];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Live Attendance",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh:     loadAttendance,

              child: Padding(
                padding: EdgeInsets.all(context.w * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Attendance Log",
                              style: TextStyle(
                                fontSize: context.w * 0.06,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Track student entry and exit logs in real-time.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        ElevatedButton.icon(
                          onPressed: () {
                            // Manual Check In
                          },
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

                    const SizedBox(height: 25),

                    /// Search + Filter
                    Wrap(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search Student",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: "All",
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "All",
                                child: Text("All"),
                              ),
                              DropdownMenuItem(
                                value: "present",
                                child: Text("Inside"),
                              ),
                              DropdownMenuItem(
                                value: "checkedout",
                                child: Text("Outside"),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// Table
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: context.w * 0.08,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Student",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Room",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Check In",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Check Out",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Status",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              DataColumn(
                                label: Text(
                                  "Action",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],

                            rows: attendanceList.map<DataRow>((item) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(item["studentName"] ?? "")),

                                  DataCell(Text(item["roomNo"] ?? "")),

                                  DataCell(
                                    Text(
                                      item["date"].toString().substring(0, 10),
                                    ),
                                  ),

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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w * 0.04,
                                        vertical: context.h * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item["status"] == "present"
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item["status"] == "present"
                                            ? "Inside"
                                            : "Outside",
                                        style: TextStyle(
                                          color: item["status"] == "present"
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    Row(
                                      children: [
                                        if (item["status"] == "present")
                                          IconButton(
                                            icon: const Icon(
                                              Icons.logout,
                                              color: Colors.orange,
                                            ),
                                            onPressed: () {
                                              // Checkout API
                                            },
                                          ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            // Delete API
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ), // yha per lagana hai
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
