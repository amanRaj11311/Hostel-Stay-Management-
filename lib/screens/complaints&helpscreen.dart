//ComplaintsAndHelpscreen

import 'package:flutter/material.dart';
import '../api/complaint_service.dart';
import '../widgets/mainlayout.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class ComplaintsAndHelpscreen extends StatefulWidget {
  const ComplaintsAndHelpscreen({super.key});

  @override
  State<ComplaintsAndHelpscreen> createState() =>
      _ComplaintsAndHelpScreenState();
}

class _ComplaintsAndHelpScreenState extends State<ComplaintsAndHelpscreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  String category = "electrical";
  String priority = "medium";

  List complaints = [];
  List stats = [];

  List filteredComplaints = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final complaintResponse = await ComplaintService.getComplaints();
    final statsResponse = await ComplaintService.getComplaintStats();

    print("Complaint Response: $complaintResponse");
    print("Stats Response: $statsResponse");

    setState(() {
      complaints = complaintResponse["data"] ?? [];
      filteredComplaints = List.from(complaints); // <-- Add this
      stats = statsResponse["data"] ?? [];
      isLoading = false;
    });
  }

  String formatDate(String? date) {
    if (date == null) return "-";

    DateTime d = DateTime.parse(date);

    return "${d.day}/${d.month}/${d.year}";
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "";

    return text[0].toUpperCase() + text.substring(1);
  }

  void searchComplaint(String value) {
    setState(() {
      filteredComplaints = complaints.where((item) {
        bool matchSearch =
            item["studentName"].toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            item["title"].toString().toLowerCase().contains(
              value.toLowerCase(),
            );

        bool matchStatus = selectedStatus == "All"
            ? true
            : item["status"] == selectedStatus;

        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Widget buildComplaintTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredComplaints.length,
      itemBuilder: (context, index) {
        final item = filteredComplaints[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        (item["studentName"] ?? "S")
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["studentName"] ?? "-",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item["complaintId"] ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    buildStatusChip(item["status"]),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        Icons.meeting_room,
                        "Room",
                        item["roomNo"] ?? "-",
                      ),
                    ),

                    Expanded(
                      child: _infoTile(
                        Icons.category,
                        "Category",
                        capitalize(item["category"]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        Icons.priority_high,
                        "Priority",
                        capitalize(item["priority"]),
                      ),
                    ),

                    Expanded(
                      child: _infoTile(
                        Icons.calendar_today,
                        "Date",
                        formatDate(item["createdAt"]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  "Complaint",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  item["title"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 5),

                Text(
                  item["description"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),

                const Divider(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Edit
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit"),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton.icon(
                      onPressed: () {
                        deleteComplaint(item["_id"]);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPriorityChip(String priority) {
    Color bg = Colors.orange.shade100;
    Color text = Colors.orange;

    if (priority == "high") {
      bg = const Color.fromARGB(255, 32, 32, 32);
      text = Colors.red;
    }

    if (priority == "low") {
      bg = Colors.green.shade100;
      text = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        capitalize(priority),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildStatusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color text = Colors.black;

    switch (status) {
      case "resolved":
        bg = Colors.green.shade100;
        text = Colors.green;
        break;

      case "pending":
        bg = Colors.red.shade100;
        text = Colors.red;
        break;

      case "in_progress":
        bg = Colors.blue.shade100;
        text = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        capitalize(status.replaceAll("_", " ")),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void showComplaintDialog() {
    showDialog(
      context: context,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Complaint"),

              content: SizedBox(
                width: 450,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      TextField(
                        controller: titleController,

                        decoration: const InputDecoration(
                          labelText: "Complaint Title",
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: descriptionController,

                        maxLines: 4,

                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField(
                        value: category,

                        decoration: const InputDecoration(
                          labelText: "Category",
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: "electrical",

                            child: Text("Electrical"),
                          ),

                          DropdownMenuItem(
                            value: "plumbing",

                            child: Text("Plumbing"),
                          ),

                          DropdownMenuItem(
                            value: "cleaning",

                            child: Text("Cleaning"),
                          ),

                          DropdownMenuItem(
                            value: "internet",

                            child: Text("Internet"),
                          ),
                        ],

                        onChanged: (value) {
                          setDialogState(() {
                            category = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField(
                        value: priority,

                        decoration: const InputDecoration(
                          labelText: "Priority",
                        ),

                        items: const [
                          DropdownMenuItem(value: "low", child: Text("Low")),

                          DropdownMenuItem(
                            value: "medium",

                            child: Text("Medium"),
                          ),

                          DropdownMenuItem(value: "high", child: Text("High")),
                        ],

                        onChanged: (value) {
                          setDialogState(() {
                            priority = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: saveComplaint,

                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveComplaint() async {
    final body = {
      "title": titleController.text,

      "description": descriptionController.text,

      "category": category,

      "priority": priority,
    };

    final response = await ComplaintService.createComplaint(body);

    if (response["success"] == true) {
      Navigator.pop(context);

      titleController.clear();

      descriptionController.clear();

      loadData();
    }
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    final response = await ComplaintService.updateStatus(id, {
      "status": status,
    });

    if (response["success"] == true) {
      loadData();
    }
  }

  Future<void> deleteComplaint(String id) async {
    final response = await ComplaintService.deleteComplaint(id);

    if (response["success"] == true) {
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Complaints",

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.w * 0.04),

              child: Column(
                children: [
                  buildTopBar(),
                  SizedBox(height: context.h * 0.02),

                  buildTopCards(),
                  SizedBox(height: context.h * 0.02),

                  buildSearchSection(),
                  SizedBox(height: context.h * 0.02),

                  buildComplaintTable(),
                ],
              ),
            ),
    );
  }

  Widget buildTopBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: showComplaintDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Complaint"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.w * 0.03,
            vertical: context.h * 0.015,
          ),
        ),
      ),
    );
  }

  Widget buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            width: context.w * 0.32,
            child: TextField(
              controller: searchController,

              onChanged: searchComplaint,

              decoration: InputDecoration(
                hintText: "Search by student, room no, complaint...",

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.w * 0.03),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        SizedBox(
          width: context.w * 0.32,
          child: DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.w * 0.03),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(value: "pending", child: Text("Pending")),
              DropdownMenuItem(value: "resolved", child: Text("Resolved")),
              DropdownMenuItem(
                value: "in_progress",
                child: Text("In Progress"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;

                // Search aur Status dono filter honge
                searchComplaint(searchController.text);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      color: Colors.grey.shade200,

      child: Row(
        children: const [
          SizedBox(
            width: 180,
            child: Text(
              "Student",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 80,
            child: Text("Room", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          SizedBox(
            width: 120,
            child: Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 250,
            child: Text(
              "Complaint",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 120,
            child: Text(
              "Priority",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 120,
            child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          SizedBox(
            width: 120,
            child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 120,
            child: Text(
              "Actions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 500 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisCount: count,

          crossAxisSpacing: 15,

          mainAxisSpacing: 15,

          childAspectRatio: 2.0,

          children: [
            dashboardCard(
              "TOTAL",
              complaints.length.toString(),
              Icons.list_alt,
              Colors.blue,
            ),

            dashboardCard(
              "PENDING",
              complaints
                  .where((e) => e["status"] == "pending")
                  .length
                  .toString(),
              Icons.pending_actions,
              Colors.orange,
            ),

            dashboardCard(
              "RESOLVED",
              complaints
                  .where((e) => e["status"] == "resolved")
                  .length
                  .toString(),
              Icons.check_circle,
              Colors.green,
            ),

            dashboardCard(
              "IN PROGRESS",
              complaints
                  .where((e) => e["status"] == "in_progress")
                  .length
                  .toString(),
              Icons.loop,
              Colors.indigo,
            ),
          ],
        );
      },
    );
  }

  Widget dashboardCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(context.w * 0.03),

        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.w * 0.028,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  value,

                  style: TextStyle(
                    fontSize: context.w * 0.026,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          CircleAvatar(
            radius: context.w * 0.045,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, size: context.w * 0.04, color: color),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
