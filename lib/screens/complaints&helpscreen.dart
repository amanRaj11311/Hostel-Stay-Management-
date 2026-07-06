//ComplaintsAndHelpscreen

import 'package:flutter/material.dart';
import '../api/complaint_service.dart';
import '../widgets/mainlayout.dart';

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
      
      itemCount: filteredComplaints.length,
      itemBuilder: (context, index) {
        final item = filteredComplaints[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
          ),
          child: Row(
            children: [
              /// Student
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["studentName"]),
                    Text(item["complaintId"]),
                  ],
                ),
              ),

              SizedBox(width: 80, child: Text(item["roomNo"])),

              SizedBox(width: 120, child: Text(capitalize(item["category"]))),

              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(item["title"]), Text(item["description"])],
                ),
              ),

              SizedBox(width: 120, child: buildPriorityChip(item["priority"])),

              SizedBox(width: 120, child: Text(formatDate(item["createdAt"]))),

              SizedBox(width: 120, child: buildStatusChip(item["status"])),

              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteComplaint(item["_id"]);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    //listview
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
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  buildTopBar(),
                  const SizedBox(height: 20),

                  buildTopCards(),
                  const SizedBox(height: 20),

                  buildSearchSection(),
                  const SizedBox(height: 20),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1110,
                      child: Column(
                        children: [
                          buildTableHeader(),

                          SizedBox(
                            height: 500, // jitni height chahiye
                            child: buildComplaintTable(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildTopBar() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Complaints",

                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 5),

              Text(
                "Track and manage student complaints.",

                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: showComplaintDialog,

          icon: const Icon(Icons.add),

          label: const Text("Add Complaint"),

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,

            foregroundColor: Colors.white,

            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,

            child: TextField(
              controller: searchController,

              onChanged: searchComplaint,

              decoration: InputDecoration(
                hintText: "Search by student, room no, complaint...",

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All Status")),
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
        int count = constraints.maxWidth > 900 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisCount: count,

          crossAxisSpacing: 15,

          mainAxisSpacing: 15,

          childAspectRatio: 2.8,

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
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(title),

                const SizedBox(height: 8),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 28,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          CircleAvatar(
            backgroundColor: color.withOpacity(.15),

            child: Icon(icon, color: color),
          ),
        ],
      ),
    );
  }
}
