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
  String selectedStatus = "All";
  List filteredAttendance = [];
  final TextEditingController searchController = TextEditingController();

  Map<String, int> stats = {
    "total": 0,
    "present": 0,
    "checkedout": 0,
  };

  static const Color _primary = Color(0xff4F46E5);
  static const Color _success = Color(0xff16A34A);
  static const Color _warning = Color(0xffF59E0B);

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAttendance() async {
    try {
      setState(() {
        isLoading = attendanceList.isEmpty;
      });
      final response = await AttendanceService.getAttendance();
      if (mounted) {
        setState(() {
          attendanceList = response["data"] ?? [];
          _calculateStats();
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _calculateStats() {
    int present = 0;
    int checkedout = 0;

    for (var item in attendanceList) {
      if (item["status"] == "present") {
        present++;
      } else if (item["status"] == "checkedout") {
        checkedout++;
      }
    }

    stats = {
      "total": attendanceList.length,
      "present": present,
      "checkedout": checkedout,
    };
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredAttendance = attendanceList.where((item) {
        final name = (item["studentName"] ?? "").toString().toLowerCase();
        final room = (item["roomNo"] ?? "").toString().toLowerCase();
        
        bool matchSearch = name.contains(query) || room.contains(query);
        bool matchStatus = selectedStatus == "All" || item["status"] == selectedStatus;

        return matchSearch && matchStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Attendance Log",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadAttendance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 25),
                        _buildKpiCards(),
                        const SizedBox(height: 25),
                        _buildSearchAndFilter(),
                        const SizedBox(height: 25),
                        if (filteredAttendance.isEmpty)
                          _buildEmptyState()
                        else
                          _buildAttendanceGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff4F46E5), Color(0xff6366F1), Color(0xff818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Live Attendance", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Track student entry and exit logs in real-time.", style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.login_rounded),
                      label: const Text("Manual Check In"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Live Attendance Registry", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text("Monitor daily movement logs and student presence status.", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.login_rounded),
                    label: const Text("Manual Entry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final spacing = isMobile ? 12.0 : 16.0;
      final columns = isMobile ? 3 : 3;
      final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _kpiCard("Total Records", "${stats["total"]}", Icons.history_rounded, _primary, itemWidth),
          _kpiCard("Inside", "${stats["present"]}", Icons.verified_user_rounded, _success, itemWidth),
          _kpiCard("Outside", "${stats["checkedout"]}", Icons.logout_rounded, _warning, itemWidth),
        ],
      );
    });
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSearchField(),
              const Divider(height: 24),
              _buildFilterDropdown(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: _buildSearchField()),
            const SizedBox(width: 16),
            Container(width: 1, height: 32, color: Colors.grey.shade200),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildFilterDropdown()),
          ],
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (v) => _applyFilters(),
      decoration: const InputDecoration(
        hintText: "Search by student name or room...",
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: _primary),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedStatus,
        isExpanded: true,
        icon: const Icon(Icons.filter_list_rounded, color: Colors.grey),
        items: const [
          DropdownMenuItem(value: "All", child: Text("All Status")),
          DropdownMenuItem(value: "present", child: Text("Inside")),
          DropdownMenuItem(value: "checkedout", child: Text("Outside")),
        ],
        onChanged: (value) {
          setState(() {
            selectedStatus = value!;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildAttendanceGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      final spacing = 20.0;
      final width = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: filteredAttendance.map((item) => SizedBox(width: width, child: _attendanceCard(item))).toList(),
      );
    });
  }

  Widget _attendanceCard(Map<String, dynamic> item) {
    final isPresent = item["status"] == "present";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(item["studentName"] ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["studentName"] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Room: ${item["roomNo"] ?? "-"}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _statusChip(isPresent),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.calendar_today_rounded, "Date", item["date"]?.toString().substring(0, 10) ?? "-"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xffF9FAFB), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _timeItem(Icons.login_rounded, "IN", item["checkIn"]?.toString().substring(11, 16) ?? "--:--"),
                const Spacer(),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                const Spacer(),
                _timeItem(Icons.logout_rounded, "OUT", item["checkOut"]?.toString().substring(11, 16) ?? "--:--"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPresent)
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("Mark Checkout"),
                  style: TextButton.styleFrom(foregroundColor: _warning),
                ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                tooltip: "Delete",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Container(
      width: 46,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primary.withOpacity(0.7), _primary]),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _statusChip(bool isPresent) {
    Color color = isPresent ? _success : _warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(isPresent ? "INSIDE" : "OUTSIDE", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _timeItem(IconData icon, String label, String time) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No attendance records found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
