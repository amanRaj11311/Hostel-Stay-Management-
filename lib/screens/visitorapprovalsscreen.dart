import 'package:flutter/material.dart';

import '../widgets/mainlayout.dart';
import '../api/visitor_service.dart';

class VisitorApprovalsScreen extends StatefulWidget {
  const VisitorApprovalsScreen({super.key});

  @override
  State<VisitorApprovalsScreen> createState() => _VisitorApprovalsScreenState();
}

class _VisitorApprovalsScreenState extends State<VisitorApprovalsScreen> {
  List visitors = [];
  List filteredVisitors = [];
  List stats = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All";

  String formatDate(String? date) {
    if (date == null) return "-";

    DateTime d = DateTime.parse(date);

    return "${d.day}/${d.month}/${d.year}";
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "";

    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final visitorResponse = await VisitorService.getVisitors();

    final statsResponse = await VisitorService.getTodayVisitors();

    setState(() {
      visitors = visitorResponse["data"] ?? [];
      filteredVisitors = visitors;

      stats = statsResponse["data"] ?? [];

      isLoading = false;
    });
  }

  Future<void> approveVisitor(String id) async {
    final response = await VisitorService.approveVisitor(id);

    if (response["success"] == true) {
      loadData();
    }
  }

  Future<void> rejectVisitor(String id) async {
    try {
      final response = await VisitorService.rejectVisitor(id, {
        "reason": "Rejected by Admin",
      });

      if (response["success"] == true) {
        loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Visitor rejected successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> checkoutVisitor(String id) async {
    final response = await VisitorService.checkoutVisitor(id);

    if (response["success"] == true) {
      loadData();
    }
  }

  void searchVisitor(String value) {
    setState(() {
      filteredVisitors = visitors.where((item) {
        bool matchSearch =
            item["visitorName"].toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            item["studentName"].toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            item["roomNo"].toString().contains(value);

        bool matchStatus = selectedStatus == "All"
            ? true
            : item["status"] == selectedStatus;

        return matchSearch && matchStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Visitor Management",

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
                      width: 1000,
                      child: Column(
                        children: [buildTableHeader(), buildVisitorTable()],
                      ),
                    ),
                  ),
                  // buildVisitorTable(),
                ],
              ),
            ),
    );
  }

  //==================== TOP BAR ====================

  Widget buildTopBar() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Visitor Management",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 5),

              Text(
                "Track and manage hostel visitors efficiently.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: () {},

          icon: const Icon(Icons.add),

          label: const Text("+ Add Visitor"),

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  //==================== TOP CARDS ====================

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
            dashboardCard("TOTAL", "25", Icons.people, Colors.blue),

            dashboardCard("PENDING", "5", Icons.pending_actions, Colors.orange),

            dashboardCard("APPROVED", "18", Icons.check_circle, Colors.green),

            dashboardCard("CHECK OUT", "2", Icons.logout, Colors.purple),
          ],
        );
      },
    );
  }

  Widget buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      color: Colors.grey.shade200,

      child: const Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              "Visitor",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 150,
            child: Text(
              "Student",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 100,
            child: Text("Room", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          SizedBox(
            width: 150,
            child: Text(
              "Mobile",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 150,
            child: Text(
              "Check In/Out",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 120,
            child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            width: 150,
            child: Text(
              "Actions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVisitorTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredVisitors.length,
      itemBuilder: (context, index) {
        final item = filteredVisitors[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
          ),

          child: Row(
            children: [
              /// Visitor Name
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["visitorName"] ?? "-",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item["phone"] ?? "",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              /// Student
              SizedBox(width: 170, child: Text(item["studentName"] ?? "-")),

              /// Relation
              SizedBox(width: 120, child: Text(capitalize(item["relation"]))),

              /// Mobile
              SizedBox(width: 150, child: Text(item["phone"] ?? "-")),

              /// Check In
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "In: ${item["checkInTime"] ?? "--"}",
                      style: const TextStyle(color: Colors.green),
                    ),

                    Text(
                      "Out: ${item["checkOutTime"] ?? "--"}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),

              /// Status
              SizedBox(
                width: 120,
                child: buildStatusChip(item["status"] ?? ""),
              ),

              /// Actions
              SizedBox(
                width: 180,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        approveVisitor(item["_id"]);
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        rejectVisitor(item["_id"]);
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.orange),
                      onPressed: () {
                        checkoutVisitor(item["_id"]);
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
  }

  Widget buildStatusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color text = Colors.black;

    switch (status) {
      case "approved":
        bg = Colors.green.shade100;
        text = Colors.green;
        break;

      case "pending":
        bg = Colors.orange.shade100;
        text = Colors.orange;
        break;

      case "rejected":
        bg = Colors.red.shade100;
        text = Colors.red;
        break;

      case "checked_out":
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
        style: TextStyle(color: text, fontWeight: FontWeight.bold),
      ),
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

  //==================== SEARCH ====================

  Widget buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,

            child: TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: "Search by visitor, student, room no...",

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

              DropdownMenuItem(value: "approved", child: Text("Approved")),

              DropdownMenuItem(value: "completed", child: Text("Completed")),
            ],

            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
          ),
        ),
      ],
    );
  }
}
