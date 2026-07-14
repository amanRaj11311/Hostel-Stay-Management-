import 'package:flutter/material.dart';
import '../api/attendance_service.dart';
import '../api/resident_service.dart';
import '../widgets/mainlayout.dart';
import 'pull_to_refresh.dart';

class LiveAttendanceScreen extends StatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  List attendanceList = [];
  List residents = [];
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
    _loadResidents();
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

  Future<void> _loadResidents() async {
    try {
      final response = await ResidentService.getResidents();
      if (mounted) {
        setState(() {
          residents = response["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading residents: $e");
    }
  }

  void _calculateStats() {
    int present = 0;
    int checkedout = 0;

    for (var item in attendanceList) {
      final statusStr = (item["status"] ?? "present").toString().toLowerCase();
      final hasCheckOut = item["checkOut"] != null && item["checkOut"].toString().isNotEmpty;

      if (hasCheckOut || statusStr == "checkedout" || statusStr == "outside") {
        checkedout++;
      } else if (statusStr == "present" || statusStr == "inside") {
        present++;
      }
    }

    stats = {
      "total": attendanceList.length,
      "present": present,
      "checkedout": checkedout,
    };
  }

  void _showManualCheckInDialog() {
    // Ensuring attendanceList is cast correctly
    final castedAttendanceList = List<Map<String, dynamic>>.from(attendanceList);

    showDialog(
      context: context,
      builder: (context) => _ManualCheckInDialog(
        attendanceList: castedAttendanceList,
        residents: residents,
        onCheckIn: _handleSmartCheckInOut,
      ),
    );
  }

  Future<void> _handleSmartCheckInOut(String residentId, String name, String roomNo) async {
    try {
      // FIX: Use .where().firstOrNull pattern instead of firstWhere with null to prevent compile errors
      final matches = attendanceList.where(
            (item) => (item["residentId"] is Map
            ? item["residentId"]["_id"]?.toString() == residentId
            : item["residentId"]?.toString() == residentId),
      );

      final todayRecord = matches.isNotEmpty ? matches.first : null;

      if (todayRecord != null) {
        final statusStr = (todayRecord["status"] ?? "present").toString().toLowerCase();
        final hasCheckOut = todayRecord["checkOut"] != null && todayRecord["checkOut"].toString().isNotEmpty;

        if ((statusStr == "present" || statusStr == "inside") && !hasCheckOut) {
          await _markCheckout(todayRecord);
        } else {
          await _handleManualCheckIn(residentId, name, roomNo);
        }
      } else {
        await _handleManualCheckIn(residentId, name, roomNo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _handleManualCheckIn(String residentId, String name, String roomNo) async {
    try {
      await AttendanceService.checkIn({"studentName": name, "roomNo": roomNo});
      loadAttendance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check-in recorded successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _markCheckout(Map<String, dynamic> item) async {
    try {
      final id = item["_id"].toString();
      await AttendanceService.checkOut(id);
      await Future.delayed(const Duration(seconds: 1));
      await loadAttendance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checkout marked successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _extractTime(dynamic dateTimeStr) {
    if (dateTimeStr == null) return "--:--";
    try {
      String str = dateTimeStr.toString();
      if (str.contains("T")) {
        DateTime utcTime = DateTime.parse(str);
        DateTime localTime = utcTime.add(const Duration(hours: 5, minutes: 30));
        String hour = localTime.hour.toString().padLeft(2, '0');
        String minute = localTime.minute.toString().padLeft(2, '0');
        return "$hour:$minute";
      }
      return "--:--";
    } catch (e) {
      return "--:--";
    }
  }

  Future<void> _deleteAttendance(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Attendance Record"),
        content: Text("Are you sure you want to delete this record for ${item["studentName"]}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AttendanceService.deleteAttendance(item["_id"].toString());
        loadAttendance();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  void _showHistoryDialog(Map<String, dynamic> item) {
    final studentName = item["studentName"] ?? "Unknown";
    final residentId = item["residentId"] is Map
        ? item["residentId"]["_id"]?.toString() ?? ""
        : item["residentId"]?.toString() ?? "";

    showDialog(
      context: context,
      builder: (context) => AttendanceHistoryDialog(
        studentName: studentName,
        residentId: residentId,
      ),
    );
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
            BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: isMobile
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Live Attendance", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text("Track student entry and exit logs in real-time.", style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showManualCheckInDialog,
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
                  Text("Monitor daily movement logs and student presence status.", style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _showManualCheckInDialog,
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
      final columns = 3;
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchField()),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          Expanded(flex: 1, child: _buildFilterDropdown()),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
    final statusStr = (item["status"] ?? "present").toString().toLowerCase();
    final hasCheckOut = item["checkOut"] != null && item["checkOut"].toString().isNotEmpty;
    final isPresent = (statusStr == "present" || statusStr == "inside") && !hasCheckOut;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
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
                _timeItem(Icons.login_rounded, "IN", _extractTime(item["checkIn"])),
                const Spacer(),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                const Spacer(),
                _timeItem(Icons.logout_rounded, "OUT", _extractTime(item["checkOut"])),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isPresent)
                TextButton.icon(
                  onPressed: () => _markCheckout(item),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("Mark Checkout"),
                  style: TextButton.styleFrom(foregroundColor: _warning),
                ),
              TextButton.icon(
                onPressed: () => _showHistoryDialog(item),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text("History"),
                style: TextButton.styleFrom(foregroundColor: _primary),
              ),
              IconButton(
                onPressed: () => _deleteAttendance(item),
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
        gradient: LinearGradient(colors: [_primary.withValues(alpha: 0.7), _primary]),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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

class _ManualCheckInDialog extends StatefulWidget {
  final List<Map<String, dynamic>> attendanceList;
  final List residents;
  final Function(String residentId, String name, String roomNo) onCheckIn;

  // FIX: Added super.key for best practices
  const _ManualCheckInDialog({
    super.key,
    required this.attendanceList,
    required this.residents,
    required this.onCheckIn,
  });

  @override
  State<_ManualCheckInDialog> createState() => _ManualCheckInDialogState();
}

class _ManualCheckInDialogState extends State<_ManualCheckInDialog> {
  // FIX: Use primitive `String?` for Dropdown state instead of `Map` to prevent equality assertion crashes
  String? selectedResidentId;
  bool isInside = false;

  String _getStatusForResident(String residentId) {
    final matches = widget.attendanceList.where(
          (item) => (item["residentId"] is Map
          ? item["residentId"]["_id"]?.toString() == residentId
          : item["residentId"]?.toString() == residentId),
    );

    final record = matches.isNotEmpty ? matches.first : null;

    if (record == null) return "No record";

    final statusStr = (record["status"] ?? "present").toString().toLowerCase();
    final hasCheckOut = record["checkOut"] != null && record["checkOut"].toString().isNotEmpty;

    if ((statusStr == "present" || statusStr == "inside") && !hasCheckOut) {
      return "Inside (Will Check-Out)";
    } else {
      return "Outside (Will Check-In)";
    }
  }

  bool _isInsideStatus(String residentId) {
    final matches = widget.attendanceList.where(
          (item) => (item["residentId"] is Map
          ? item["residentId"]["_id"]?.toString() == residentId
          : item["residentId"]?.toString() == residentId),
    );

    final record = matches.isNotEmpty ? matches.first : null;

    if (record == null) return false;

    final statusStr = (record["status"] ?? "present").toString().toLowerCase();
    final hasCheckOut = record["checkOut"] != null && record["checkOut"].toString().isNotEmpty;

    return (statusStr == "present" || statusStr == "inside") && !hasCheckOut;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Manual Check-In/Check-Out"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.residents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No residents available", style: TextStyle(color: Colors.grey)),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedResidentId,
                hint: const Text("Select Student"),
                decoration: InputDecoration(
                  labelText: "Student",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                // FIX: Using String `id` as the Dropdown item value
                items: widget.residents.map<DropdownMenuItem<String>>((resident) {
                  final id = resident["_id"]?.toString() ?? "";
                  final name = resident["name"]?.toString() ?? "Unknown";
                  final roomNo = resident["roomNo"]?.toString() ?? "-";
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text("$name (Room $roomNo)"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedResidentId = value;
                    if (value != null) {
                      isInside = _isInsideStatus(value);
                    }
                  });
                },
              ),
            if (selectedResidentId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isInside ? const Color(0xffDCFCE7) : const Color(0xffFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInside ? const Color(0xff16A34A) : const Color(0xffF59E0B),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInside ? Icons.check_circle_rounded : Icons.logout_rounded,
                      color: isInside ? const Color(0xff16A34A) : const Color(0xffF59E0B),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Status",
                            style: TextStyle(
                              fontSize: 12,
                              color: isInside ? const Color(0xff16A34A) : const Color(0xffF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusForResident(selectedResidentId!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isInside ? const Color(0xff16A34A) : const Color(0xffD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        if (selectedResidentId != null)
          ElevatedButton(
            onPressed: () {
              final resident = widget.residents.firstWhere((r) => r["_id"]?.toString() == selectedResidentId);
              widget.onCheckIn(
                selectedResidentId!,
                resident["name"]?.toString() ?? "",
                resident["roomNo"]?.toString() ?? "",
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isInside ? Colors.orange : const Color(0xff16A34A),
              foregroundColor: Colors.white,
            ),
            child: Text(isInside ? "Check Out" : "Check In"),
          ),
      ],
    );
  }
}

class AttendanceHistoryDialog extends StatefulWidget {
  final String studentName;
  final String residentId;

  const AttendanceHistoryDialog({
    super.key,
    required this.studentName,
    required this.residentId,
  });

  @override
  State<AttendanceHistoryDialog> createState() => _AttendanceHistoryDialogState();
}

class _AttendanceHistoryDialogState extends State<AttendanceHistoryDialog> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await AttendanceService.getAttendanceByResident(widget.residentId);
      if (mounted) {
        setState(() {
          history = List<Map<String, dynamic>>.from(response["data"] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading history: Check backend API endpoint!\n($e)"),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper method to group history data day-wise
  Map<String, List<Map<String, dynamic>>> _getGroupedHistory() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var record in history) {
      final dateKey = _formatDate(record["date"]);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Unknown Date";
    try {
      String str = dateStr.toString();
      if (str.contains("T")) {
        return str.substring(0, 10); // Extracts YYYY-MM-DD
      }
      return str;
    } catch (e) {
      return "Unknown Date";
    }
  }

  String _formatTime(dynamic dateTimeStr) {
    if (dateTimeStr == null) return "--:--";
    try {
      String str = dateTimeStr.toString();
      if (str.contains("T")) {
        int tIndex = str.indexOf("T");
        String timePart = str.substring(tIndex + 1);
        return timePart.length >= 5 ? timePart.substring(0, 5) : "--:--";
      }
      return str.length >= 5 ? str.substring(0, 5) : "--:--";
    } catch (e) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _getGroupedHistory();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Color(0xff4F46E5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Attendance History (Day-Wise)",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.studentName,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      "No attendance records available",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  ],
                ),
              )
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: groupedData.entries.map((entry) {
                  final String dayStr = entry.key;
                  final List<Map<String, dynamic>> dayRecords = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day Header Badge
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dayStr,
                          style: const TextStyle(
                            color: Color(0xff4F46E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Logs for this specific day
                      ...dayRecords.map((record) {
                        final checkIn = _formatTime(record["checkIn"]);
                        final checkOut = _formatTime(record["checkOut"]);
                        final status = (record["status"] ?? "present").toString().toUpperCase();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Check-In", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          Text(checkIn, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Check-Out", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          Text(checkOut, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: status == "CHECKEDOUT" || status == "OUTSIDE"
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status == "CHECKEDOUT" || status == "OUTSIDE" ? "OUT" : "IN",
                                  style: TextStyle(
                                    color: status == "CHECKEDOUT" || status == "OUTSIDE"
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text("Export CSV"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4F46E5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToCSV() {
    StringBuffer csv = StringBuffer();
    csv.writeln("Student Name,Date,Check-In,Check-Out,Status");

    for (var record in history) {
      final date = _formatDate(record["date"]);
      final checkIn = _formatTime(record["checkIn"]);
      final checkOut = _formatTime(record["checkOut"]);
      final status = (record["status"] ?? "present").toString();
      csv.writeln("${widget.studentName},$date,$checkIn,$checkOut,$status");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("CSV prepared: ${history.length} records"),
        action: SnackBarAction(label: "OK", onPressed: () {}),
      ),
    );
  }
}

