import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/visitor_service.dart';
import '../api/resident_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class VisitorApprovalsScreen extends StatefulWidget {
  const VisitorApprovalsScreen({super.key});

  @override
  State<VisitorApprovalsScreen> createState() => _VisitorApprovalsScreenState();
}

class _VisitorApprovalsScreenState extends State<VisitorApprovalsScreen> {
  List<Map<String, dynamic>> visitors = [];
  List<Map<String, dynamic>> filteredVisitors = [];
  List<Map<String, dynamic>> residents = [];
  Map<String, dynamic> visitorStats = {
    "total": 0,
    "pending": 0,
    "approved": 0,
    "checked_out": 0,
  };

  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String selectedFilterStatus = "All";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await Future.wait([
      loadData(),
      loadResidents(),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> loadResidents() async {
    try {
      final response = await ResidentService.getResidents();
      final data = response['data'];
      
      final loadedResidents = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          residents = loadedResidents;
        });
      }
    } catch (e) {
      debugPrint("Error loading residents: $e");
    }
  }

  Future<void> loadData() async {
    try {
      final visitorResponse = await VisitorService.getVisitors();
      
      if (mounted) {
        setState(() {
          final data = visitorResponse["data"];
          visitors = data is List 
              ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
          _applyFilters();
          _calculateStats();
        });
      }
    } catch (e) {
      debugPrint("Error loading visitors: $e");
    }
  }

  void _calculateStats() {
    int pending = 0;
    int approved = 0;
    int checkedOut = 0;

    for (var v in visitors) {
      final status = v["status"]?.toString().toLowerCase();
      if (status == "pending") pending++;
      else if (status == "approved") approved++;
      else if (status == "checked_out") checkedOut++;
    }

    visitorStats = {
      "total": visitors.length,
      "pending": pending,
      "approved": approved,
      "checked_out": checkedOut,
    };
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredVisitors = visitors.where((item) {
        final visitorName = (item["visitorName"] ?? "").toString().toLowerCase();
        final studentName = (item["studentName"] ?? "").toString().toLowerCase();
        final roomNo = (item["roomNo"] ?? "").toString().toLowerCase();
        
        bool matchSearch = visitorName.contains(query) || 
                          studentName.contains(query) || 
                          roomNo.contains(query);

        bool matchStatus = selectedFilterStatus == "All"
            ? true
            : item["status"]?.toString().toLowerCase() == selectedFilterStatus.toLowerCase();

        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Future<void> _approveVisitor(String id) async {
    try {
      final response = await VisitorService.approveVisitor(id);
      if (response["success"] == true) {
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visitor approved successfully"), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rejectVisitor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Visitor"),
        content: const Text("Are you sure you want to reject this visitor request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await VisitorService.rejectVisitor(id, {"reason": "Rejected by Admin"});
        if (response["success"] == true) {
          loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Visitor rejected"), behavior: SnackBarBehavior.floating),
            );
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _checkoutVisitor(String id) async {
    try {
      final response = await VisitorService.checkoutVisitor(id);
      if (response["success"] == true) {
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visitor checked out"), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Visitor Log",
      body: Container(
        color: const Color(0xffF6F8FC),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : PullToRefresh(
                onRefresh: loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildKpiCards(),
                          const SizedBox(height: 24),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 24),
                          if (filteredVisitors.isEmpty)
                            const _EmptyVisitorsState()
                          else
                            _buildVisitorGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4F46E5), Color(0xff6366F1), Color(0xff818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6366F1).withOpacity(.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Visitor Approvals",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Monitor guest entries, manage approvals, and track check-out times for hostel security.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddVisitorDialog(),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text("New Entry"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth > 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 2.0,
        children: [
          _buildKpiCard("Total Visitors", "${visitorStats["total"]}", Icons.people_rounded, const Color(0xff6366F1)),
          _buildKpiCard("Pending Approval", "${visitorStats["pending"]}", Icons.hourglass_empty_rounded, const Color(0xffF59E0B)),
          _buildKpiCard("Currently In", "${visitorStats["approved"]}", Icons.login_rounded, const Color(0xff10B981)),
          _buildKpiCard("Checked Out", "${visitorStats["checked_out"]}", Icons.logout_rounded, const Color(0xff64748B)),
        ],
      );
    });
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff111827))),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
            Expanded(flex: 2, child: _buildFilterDropdown()),
          ],
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (v) => _applyFilters(),
      decoration: InputDecoration(
        hintText: "Search visitor, student or room...",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xff6366F1)),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedFilterStatus,
        isExpanded: true,
        icon: const Icon(Icons.filter_list_rounded, color: Colors.grey),
        items: const [
          DropdownMenuItem(value: "All", child: Text("All Status")),
          DropdownMenuItem(value: "pending", child: Text("Pending")),
          DropdownMenuItem(value: "approved", child: Text("Approved")),
          DropdownMenuItem(value: "rejected", child: Text("Rejected")),
          DropdownMenuItem(value: "checked_out", child: Text("Checked Out")),
        ],
        onChanged: (value) {
          setState(() {
            selectedFilterStatus = value!;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildVisitorGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: filteredVisitors.map((item) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
            child: VisitorCard(
              visitor: item,
              onApprove: () => _approveVisitor(item["_id"]),
              onReject: () => _rejectVisitor(item["_id"]),
              onCheckout: () => _checkoutVisitor(item["_id"]),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showAddVisitorDialog() {
    showDialog(
      context: context,
      builder: (context) => VisitorFormDialog(
        residents: residents,
        onSaved: loadData,
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  final Map visitor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCheckout;

  const VisitorCard({
    super.key,
    required this.visitor,
    required this.onApprove,
    required this.onReject,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final status = (visitor["status"] ?? "pending").toString().toLowerCase();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(visitor["visitorName"] ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visitor["visitorName"] ?? "Unknown Visitor", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(visitor["phone"] ?? "No Phone", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InfoBox(icon: Icons.person_outline_rounded, label: "Visiting Student", value: visitor["studentName"] ?? "-")),
              const SizedBox(width: 12),
              Expanded(child: _InfoBox(icon: Icons.meeting_room_rounded, label: "Room No", value: visitor["roomNo"] ?? "-")),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoBox(icon: Icons.family_restroom_rounded, label: "Relation", value: visitor["relation"] ?? "-")),
              const SizedBox(width: 12),
              Expanded(child: _InfoBox(icon: Icons.calendar_today_rounded, label: "Date", value: _formatDate(visitor["createdAt"]))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xffF9FAFB), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _TimeItem(icon: Icons.login_rounded, label: "IN", time: visitor["checkInTime"] ?? "--:--"),
                const Spacer(),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                const Spacer(),
                _TimeItem(icon: Icons.logout_rounded, label: "OUT", time: visitor["checkOutTime"] ?? "--:--"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (status == "pending")
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xffFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            )
          else if (status == "approved")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("Mark Check-Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xff6366F1).withOpacity(0.8), const Color(0xff4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    try {
      final d = DateTime.parse(date.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return date.toString();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String label = status.toUpperCase();

    if (status == "approved") color = const Color(0xff10B981);
    else if (status == "pending") color = const Color(0xffF59E0B);
    else if (status == "rejected") color = const Color(0xffEF4444);
    else if (status == "checked_out") {
      color = const Color(0xff6366F1);
      label = "CHECKED OUT";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff374151)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TimeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _TimeItem({required this.icon, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff6366F1)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xff1F2937))),
          ],
        ),
      ],
    );
  }
}

class _EmptyVisitorsState extends StatelessWidget {
  const _EmptyVisitorsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.person_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              "No Visitors Found",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff374151)),
            ),
            const SizedBox(height: 10),
            Text(
              "There are no visitor requests matching your current selection.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class VisitorFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> residents;
  final VoidCallback onSaved;

  const VisitorFormDialog({super.key, required this.residents, required this.onSaved});

  @override
  State<VisitorFormDialog> createState() => _VisitorFormDialogState();
}

class _VisitorFormDialogState extends State<VisitorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final visitorNameController = TextEditingController();
  final phoneController = TextEditingController();
  final relationController = TextEditingController();
  final purposeController = TextEditingController();
  
  String? selectedResidentId;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    visitorNameController.dispose();
    phoneController.dispose();
    relationController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || selectedResidentId == null) {
      if (selectedResidentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a resident")));
      }
      return;
    }

    final resident = widget.residents.firstWhere((r) => r["_id"].toString() == selectedResidentId);
    
    final body = {
      "visitorName": visitorNameController.text.trim(),
      "phone": phoneController.text.trim(),
      "relation": relationController.text.trim(),
      "residentId": selectedResidentId,
      "studentName": resident["name"],
      "roomNo": resident["roomNo"],
      "purpose": purposeController.text.trim(),
      "checkInTime": "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
      "status": "pending",
    };

    try {
      await VisitorService.createVisitor(body);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving visitor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: Color(0xff4F46E5), size: 28),
                  const SizedBox(width: 12),
                  const Text("Add Visitor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text("Fill visitor details for hostel entry management", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildField("Visitor Name *", visitorNameController, "Full name")),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField("Mobile Number *", phoneController, "10-digit number", keyboardType: TextInputType.phone)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildField("Relation *", relationController, "e.g. Father, Friend")),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Select Resident *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedResidentId,
                                  isExpanded: true,
                                  hint: const Text("Select a resident"),
                                  decoration: _buildInputDecoration(""),
                                  items: widget.residents.map((r) => DropdownMenuItem<String>(
                                    value: r["_id"].toString(),
                                    child: Text("${r["name"]} (${r["residentId"]})"),
                                  )).toList(),
                                  onChanged: (val) => setState(() => selectedResidentId = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField("Purpose of Visit", purposeController, "Briefly explain the reason"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Visit Date", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                                    if (date != null) setState(() => selectedDate = date);
                                  },
                                  child: _buildPickerBox("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", Icons.calendar_month_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Check In Time", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                                    if (time != null) setState(() => selectedTime = time);
                                  },
                                  child: _buildPickerBox(selectedTime.format(context), Icons.access_time_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Add Visitor"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
          decoration: _buildInputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildPickerBox(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 14)),
          Icon(icon, size: 18, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff4F46E5), width: 1.5)),
    );
  }
}
