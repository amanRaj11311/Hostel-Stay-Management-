import 'package:flutter/material.dart';

import '../widgets/mainlayout.dart';

import '../api/visitor_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

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
  bool showSearch = false;

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
          : PullToRefresh(
              onRefresh: loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    buildTopBar(),

                    const SizedBox(height: 20),

                    // buildTopCards(),
                    const SizedBox(height: 20),

                    buildSearchSection(),

                    const SizedBox(height: 20),
                    buildVisitorCards(),
                    // buildVisitorTable(),
                  ],
                ),
              ),
            ),
    );
  }

  //==================== TOP BAR ====================

  Widget buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Visitor Management",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed: () {},

              icon: const Icon(Icons.add),

              label: const Text("Add Visitor"),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          "Track and manage hostel visitors efficiently.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  //==================== TOP CARDS ====================

  /*Widget buildTopCards() {
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
  }*/

  Widget buildVisitorCards() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredVisitors.length,
      itemBuilder: (context, index) {
        final item = filteredVisitors[index];

        final status = item["status"] ?? "pending";

        Color statusColor;

        switch (status) {
          case "approved":
            statusColor = Colors.green;
            break;
          case "rejected":
            statusColor = Colors.red;
            break;
          case "checked_out":
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.blue;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
                      radius: 25,
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        (item["visitorName"] ?? "V")
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["visitorName"] ?? "-",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item["phone"] ?? "-",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    buildStatusChip(status),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        Icons.person,
                        "Student",
                        item["studentName"] ?? "-",
                      ),
                    ),

                    Expanded(
                      child: _infoTile(
                        Icons.people,
                        "Relation",
                        capitalize(item["relation"]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

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
                        Icons.calendar_today,
                        "Date",
                        formatDate(item["createdAt"]),
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
                        item["checkInTime"] ?? "--",
                      ),
                    ),

                    Expanded(
                      child: _infoTile(
                        Icons.logout,
                        "Check Out",
                        item["checkOutTime"] ?? "--",
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: "Approve",
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        approveVisitor(item["_id"]);
                      },
                    ),

                    IconButton(
                      tooltip: "Reject",
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        rejectVisitor(item["_id"]);
                      },
                    ),

                    IconButton(
                      tooltip: "Check Out",
                      icon: const Icon(Icons.logout, color: Colors.orange),
                      onPressed: () {
                        checkoutVisitor(item["_id"]);
                      },
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

  //==================== SEARCH ====================

  Widget buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      showSearch = true;
                    });
                  },
                ),

                const SizedBox(width: 15),

                SizedBox(width: 180, child: statusDropdown()),
              ],
            ),

          if (showSearch) ...[
            TextField(
              controller: searchController,
              onChanged: searchVisitor,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showSearch = false;
                      searchController.clear();
                    });
                    searchVisitor("");
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(width: double.infinity, child: statusDropdown()),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.indigo.withOpacity(.08),
          child: Icon(icon, size: 18, color: Colors.indigo),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget statusDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: "All", child: Text("All Status")),
        DropdownMenuItem(value: "pending", child: Text("Pending")),
        DropdownMenuItem(value: "approved", child: Text("Approved")),
        DropdownMenuItem(value: "checked_out", child: Text("checked_out")),
      ],
      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
        searchVisitor(searchController.text);
      },
    );
  }
}
