import 'package:flutter/material.dart';
import '../api/complaint_service.dart';
import '../api/resident_service.dart';
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
  final TextEditingController searchController = TextEditingController();

  String selectedStatus = "All";
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  List<Map<String, dynamic>> residents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await loadResidents();
    await loadData();
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
      setState(() => isLoading = complaints.isEmpty);
      final complaintResponse = await ComplaintService.getComplaints();
      
      if (mounted) {
        setState(() {
          final data = complaintResponse["data"];
          complaints = data is List 
              ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error loading complaints: $e");
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredComplaints = complaints.where((item) {
        final studentName = (item["studentName"] ?? "").toString().toLowerCase();
        final title = (item["title"] ?? "").toString().toLowerCase();
        final roomNo = (item["roomNo"] ?? "").toString().toLowerCase();
        
        bool matchSearch = studentName.contains(query) || 
                          title.contains(query) || 
                          roomNo.contains(query);

        bool matchStatus = selectedStatus == "All"
            ? true
            : item["status"] == selectedStatus;

        return matchSearch && matchStatus;
      }).toList();
    });
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "";
    return text[0].toUpperCase() + text.substring(1).replaceAll("_", " ");
  }

  Future<void> deleteComplaint(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Complaint"),
        content: const Text("Are you sure you want to remove this complaint record? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ComplaintService.deleteComplaint(id);
      if (response["success"] == true) {
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint deleted successfully")));
        }
      }
    }
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final response = await ComplaintService.updateStatus(id, {"status": newStatus});
    if (response["success"] == true) {
      loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to ${capitalize(newStatus)}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Complaints & Help",
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
                          if (filteredComplaints.isEmpty)
                            const _EmptyComplaintsState()
                          else
                            _buildComplaintsGrid(),
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
          colors: [Color(0xffDC2626), Color(0xffEF4444), Color(0xffF87171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffDC2626).withOpacity(.2),
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
                  "Support Center",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Track and manage resident complaints, maintenance requests, and help queries.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showComplaintDialog(),
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text("New Complaint"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xffDC2626),
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
        childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 2,
        children: [
          _buildKpiCard("Total Requests", complaints.length.toString(), Icons.analytics_rounded, const Color(0xff2563EB)),
          _buildKpiCard("Pending", complaints.where((e) => e["status"] == "pending").length.toString(), Icons.pending_rounded, const Color(0xffF59E0B)),
          _buildKpiCard("Urgent", complaints.where((e) => e["status"] == "urgent").length.toString(), Icons.error_rounded, const Color(0xffDC2626)),
          _buildKpiCard("Resolved", complaints.where((e) => e["status"] == "resolved").length.toString(), Icons.check_circle_rounded, const Color(0xff10B981)),
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
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827))),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        hintText: "Search by student, title, room...",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xffDC2626)),
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
          DropdownMenuItem(value: "pending", child: Text("Pending")),
          DropdownMenuItem(value: "urgent", child: Text("Urgent")),
          DropdownMenuItem(value: "in_progress", child: Text("In Progress")),
          DropdownMenuItem(value: "resolved", child: Text("Resolved")),
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

  Widget _buildComplaintsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: filteredComplaints.map((item) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
            child: ComplaintCard(
              complaint: item,
              onDelete: () => deleteComplaint(item["_id"]),
              onStatusChange: (status) => updateStatus(item["_id"], status),
              onEdit: () => _showComplaintDialog(complaint: item),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showComplaintDialog({Map<String, dynamic>? complaint}) {
    showDialog(
      context: context,
      builder: (context) => ComplaintFormDialog(
        complaint: complaint,
        residents: residents,
        onSaved: loadData,
      ),
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;
  final VoidCallback onEdit;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onDelete,
    required this.onStatusChange,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = complaint["status"] ?? "pending";
    final priority = complaint["priority"] ?? "medium";
    
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
              _buildAvatar(complaint["studentName"] ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complaint["studentName"] ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Room: ${complaint["roomNo"] ?? "-"}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _InfoPill(icon: Icons.category_outlined, label: (complaint["category"] ?? "General").toString().toUpperCase()),
              const SizedBox(width: 8),
              _PriorityBadge(priority: priority),
            ],
          ),
          const SizedBox(height: 20),
          Text(complaint["title"] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff111827))),
          const SizedBox(height: 6),
          Text(
            complaint["description"] ?? "No description provided.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                _formatDate(complaint["createdAt"]),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildActionMenu(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffDC2626), Color(0xffF87171)]),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
        if (val == 'pending' || val == 'in_progress' || val == 'resolved' || val == 'urgent') onStatusChange(val);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.blue), SizedBox(width: 10), Text("Edit")])),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, child: Text("Change Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
        const PopupMenuItem(value: 'pending', child: Row(children: [Icon(Icons.pending_rounded, size: 18, color: Colors.orange), SizedBox(width: 10), Text("Pending")])),
        const PopupMenuItem(value: 'urgent', child: Row(children: [Icon(Icons.error_rounded, size: 18, color: Colors.red), SizedBox(width: 10), Text("Urgent")])),
        const PopupMenuItem(value: 'in_progress', child: Row(children: [Icon(Icons.sync_rounded, size: 18, color: Colors.blue), SizedBox(width: 10), Text("In Progress")])),
        const PopupMenuItem(value: 'resolved', child: Row(children: [Icon(Icons.check_circle_rounded, size: 18, color: Colors.green), SizedBox(width: 10), Text("Resolved")])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))])),
      ],
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    switch (status) {
      case 'resolved': color = const Color(0xff10B981); break;
      case 'pending': color = const Color(0xffF59E0B); break;
      case 'urgent': color = const Color(0xffDC2626); break;
      case 'in_progress': color = const Color(0xff3B82F6); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase().replaceAll("_", " "), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (priority == 'urgent') color = const Color(0xffDC2626);
    else if (priority == 'high') color = const Color(0xffEF4444);
    else if (priority == 'medium') color = const Color(0xffF59E0B);
    else if (priority == 'low') color = const Color(0xff10B981);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ComplaintFormDialog extends StatefulWidget {
  final Map<String, dynamic>? complaint;
  final List<Map<String, dynamic>> residents;
  final VoidCallback onSaved;

  const ComplaintFormDialog({super.key, this.complaint, required this.residents, required this.onSaved});

  @override
  State<ComplaintFormDialog> createState() => _ComplaintFormDialogState();
}

class _ComplaintFormDialogState extends State<ComplaintFormDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final customCategoryController = TextEditingController();
  
  String? selectedResidentId;
  String category = "electrical";
  String priority = "medium";

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      titleController.text = widget.complaint!["title"] ?? "";
      descriptionController.text = widget.complaint!["description"] ?? "";
      category = widget.complaint!["category"] ?? "electrical";
      priority = widget.complaint!["priority"] ?? "medium";
      
      var resId = widget.complaint!["residentId"];
      String? id;
      if (resId is Map) {
        id = resId["_id"]?.toString();
      } else {
        id = resId?.toString();
      }

      // Pre-select only if it exists in current residents list
      if (widget.residents.any((r) => r["_id"]?.toString() == id)) {
        selectedResidentId = id;
      }
      
      final standardCategories = ["electrical", "plumbing", "cleaning", "internet", "furniture"];
      if (!standardCategories.contains(category)) {
        customCategoryController.text = category;
        category = "custom";
      }
    }
  }

  Future<void> _handleSave() async {
    if (selectedResidentId == null || titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resident, title and description are required")));
      return;
    }

    String finalCategory = category;
    if (category == "custom") {
      finalCategory = customCategoryController.text.trim();
      if (finalCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please specify the custom category")));
        return;
      }
    }

    final body = {
      "residentId": selectedResidentId,
      "title": titleController.text.trim(),
      "description": descriptionController.text.trim(),
      "category": finalCategory,
      "priority": priority,
    };

    try {
      if (widget.complaint != null) {
         await ComplaintService.createComplaint(body);
      } else {
        await ComplaintService.createComplaint(body);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving complaint: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.complaint != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Icon(isEditing ? Icons.edit_note_rounded : Icons.add_comment_rounded, color: const Color(0xffDC2626), size: 28),
                  const SizedBox(width: 12),
                  Text(isEditing ? "Edit Complaint" : "New Complaint", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Select Resident *"),
                    DropdownButtonFormField<String>(
                      value: selectedResidentId,
                      isExpanded: true,
                      hint: const Text("Choose a resident"),
                      decoration: _buildInputDecoration("Choose a resident"),
                      items: widget.residents.map((r) {
                        final String name = r["name"]?.toString() ?? "Unknown";
                        final String room = r["roomNo"]?.toString() ?? "-";
                        final String id = r["_id"]?.toString() ?? "";
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text("$name (Room $room)"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedResidentId = val),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Complaint Title *"),
                    TextField(controller: titleController, decoration: _buildInputDecoration("e.g. Fan not working")),
                    const SizedBox(height: 20),
                    _buildLabel("Description *"),
                    TextField(controller: descriptionController, maxLines: 3, decoration: _buildInputDecoration("Describe the issue in detail...")),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            "Category", 
                            category, 
                            ["electrical", "plumbing", "cleaning", "internet", "furniture", "custom"], 
                            (val) => setState(() => category = val!)
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdownField("Priority", priority, ["low", "medium", "high", "urgent"], (val) => setState(() => priority = val!))),
                      ],
                    ),
                    if (category == "custom") ...[
                      const SizedBox(height: 20),
                      _buildLabel("Custom Category *"),
                      TextField(controller: customCategoryController, decoration: _buildInputDecoration("e.g. Carpentry, Painting")),
                    ],
                  ],
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
                      backgroundColor: const Color(0xffDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? "Update" : "Submit"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14)),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: _buildInputDecoration(""),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1), style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffDC2626), width: 1.5)),
    );
  }
}

class _EmptyComplaintsState extends StatelessWidget {
  const _EmptyComplaintsState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.support_agent_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No Complaints Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Great news! There are no complaints matching your current filters.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
