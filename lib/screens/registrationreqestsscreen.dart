import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/registration_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class RegistrationReqestsScreen extends StatefulWidget {
  const RegistrationReqestsScreen({super.key});

  @override
  State<RegistrationReqestsScreen> createState() =>
      _RegistrationReqestsScreenState();
}

class _RegistrationReqestsScreenState extends State<RegistrationReqestsScreen> {
  final regIdController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final rollNoController = TextEditingController();
  final courseController = TextEditingController();
  final yearSemController = TextEditingController();
  final collegeController = TextEditingController();
  final addressController = TextEditingController();
  final durationController = TextEditingController();
  final adminNoteController = TextEditingController();

  String selectedRoomType = "AC";
  String selectedBlock = "Block A";
  String selectedStatus = "pending";

  DateTime? selectedCheckInDate;

  List registrations = [];
  List filteredRegistrations = [];
  bool isLoading = true;

  Map<String, int> stats = {
    "total": 0,
    "pending": 0,
    "approved": 0,
    "rejected": 0,
  };

  final TextEditingController searchController = TextEditingController();

  static const Color _primary = Color(0xff635BFF);
  static const Color _success = Color(0xff16A34A);
  static const Color _warning = Color(0xffF59E0B);
  static const Color _danger = Color(0xffEF4444);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    regIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    parentPhoneController.dispose();
    bloodGroupController.dispose();
    rollNoController.dispose();
    courseController.dispose();
    yearSemController.dispose();
    collegeController.dispose();
    addressController.dispose();
    durationController.dispose();
    adminNoteController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = registrations.isEmpty;
      });

      final response = await RegistrationService.getRegistrations();
      
      if (mounted) {
        setState(() {
          registrations = response["data"] ?? [];
          _calculateStats();
          _filterRegistrations();
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
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (var r in registrations) {
      String status = (r["status"] ?? "").toString().toLowerCase();
      if (status == "approved") approved++;
      else if (status == "rejected") rejected++;
      else pending++;
    }

    stats = {
      "total": registrations.length,
      "pending": pending,
      "approved": approved,
      "rejected": rejected,
    };
  }

  void _filterRegistrations() {
    final value = searchController.text;
    setState(() {
      if (value.isEmpty) {
        filteredRegistrations = List.from(registrations);
      } else {
        filteredRegistrations = registrations.where((r) {
          final name = (r["name"] ?? "").toString().toLowerCase();
          final regId = (r["regId"] ?? "").toString().toLowerCase();
          final query = value.toLowerCase();
          return name.contains(query) || regId.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _approveRequest(String id) async {
    try {
      await RegistrationService.approveRegistration(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Approved")));
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rejectRequest(String id) async {
    try {
      await RegistrationService.rejectRegistration(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Rejected")));
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteRegistration(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Request"),
        content: const Text("Are you sure you want to remove this registration request?"),
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
      try {
        await RegistrationService.deleteRegistration(id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Deleted")));
        loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _saveRegistration(Map<String, dynamic>? registration) async {
    try {
      final body = {
        "regId": regIdController.text.trim(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "parentPhone": parentPhoneController.text.trim(),
        "bloodGroup": bloodGroupController.text.trim(),
        "rollNo": rollNoController.text.trim(),
        "course": courseController.text.trim(),
        "yearSem": yearSemController.text.trim(),
        "college": collegeController.text.trim(),
        "address": addressController.text.trim(),
        "roomType": selectedRoomType,
        "preferredBlock": selectedBlock,
        "checkInDate": (selectedCheckInDate ?? DateTime.now()).toIso8601String(),
        "duration": durationController.text.trim(),
        "status": selectedStatus,
        "documents": {},
        "adminNote": adminNoteController.text.trim(),
      };

      if (registration == null) {
        await RegistrationService.createRegistration(body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Created Successfully")),
        );
      } else {
        await RegistrationService.updateRegistration(registration["_id"], body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Updated Successfully")),
        );
      }

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showRegistrationDialog({Map<String, dynamic>? registration}) {
    if (registration != null) {
      regIdController.text = registration["regId"] ?? "";
      nameController.text = registration["name"] ?? "";
      emailController.text = registration["email"] ?? "";
      phoneController.text = registration["phone"] ?? "";
      parentPhoneController.text = registration["parentPhone"] ?? "";
      bloodGroupController.text = registration["bloodGroup"] ?? "";
      rollNoController.text = registration["rollNo"] ?? "";
      courseController.text = registration["course"] ?? "";
      yearSemController.text = registration["yearSem"] ?? "";
      collegeController.text = registration["college"] ?? "";
      addressController.text = registration["address"] ?? "";
      durationController.text = registration["duration"] ?? "";
      adminNoteController.text = registration["adminNote"] ?? "";

      String status = registration["status"]?.toString().toLowerCase() ?? "pending";
      if (status == "approved") selectedStatus = "approved";
      else if (status == "rejected") selectedStatus = "rejected";
      else selectedStatus = "pending";

      String roomType = registration["roomType"]?.toString() ?? "AC";
      selectedRoomType = (roomType == "Non AC" || roomType.toLowerCase().contains("non")) ? "Non AC" : "AC";

      String block = registration["preferredBlock"]?.toString().toUpperCase() ?? "BLOCK A";
      if (block.contains("B")) selectedBlock = "Block B";
      else if (block.contains("C")) selectedBlock = "Block C";
      else selectedBlock = "Block A";

      if (registration["checkInDate"] != null) {
        selectedCheckInDate = DateTime.parse(registration["checkInDate"]);
      }
    } else {
      regIdController.clear();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      parentPhoneController.clear();
      bloodGroupController.clear();
      rollNoController.clear();
      courseController.clear();
      yearSemController.clear();
      collegeController.clear();
      addressController.clear();
      durationController.clear();
      adminNoteController.clear();

      selectedStatus = "pending";
      selectedRoomType = "AC";
      selectedBlock = "Block A";
      selectedCheckInDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(registration == null ? Icons.add_circle_outline : Icons.edit_note, color: _primary),
                  const SizedBox(width: 10),
                  Text(registration == null ? "Create Request" : "Edit Request"),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(regIdController, "Registration ID", Icons.tag),
                      _field(nameController, "Student Name", Icons.person_outline),
                      Row(
                        children: [
                          Expanded(child: _field(emailController, "Email", Icons.email_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(phoneController, "Phone", Icons.phone_android)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _field(parentPhoneController, "Parent Phone", Icons.family_restroom)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(bloodGroupController, "Blood Group", Icons.bloodtype_outlined)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _field(rollNoController, "Roll No", Icons.numbers)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(courseController, "Course", Icons.school_outlined)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _field(yearSemController, "Year / Semester", Icons.calendar_view_day)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(collegeController, "College", Icons.account_balance_outlined)),
                        ],
                      ),
                      _field(addressController, "Address", Icons.location_on_outlined, maxLines: 2),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedRoomType,
                              decoration: const InputDecoration(labelText: "Room Type", border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: "AC", child: Text("AC")),
                                DropdownMenuItem(value: "Non AC", child: Text("Non AC")),
                              ],
                              onChanged: (value) => dialogSetState(() => selectedRoomType = value!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedBlock,
                              decoration: const InputDecoration(labelText: "Preferred Block", border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: "Block A", child: Text("Block A")),
                                DropdownMenuItem(value: "Block B", child: Text("Block B")),
                                DropdownMenuItem(value: "Block C", child: Text("Block C")),
                              ],
                              onChanged: (value) => dialogSetState(() => selectedBlock = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _field(durationController, "Duration", Icons.timer_outlined)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedCheckInDate ?? DateTime.now(),
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2035),
                                );
                                if (date != null) dialogSetState(() => selectedCheckInDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: "Check In Date", border: OutlineInputBorder()),
                                child: Text(selectedCheckInDate == null ? "Select Date" : "${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _field(adminNoteController, "Admin Note", Icons.note_alt_outlined, maxLines: 2),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: "pending", child: Text("Pending")),
                          DropdownMenuItem(value: "approved", child: Text("Approved")),
                          DropdownMenuItem(value: "rejected", child: Text("Rejected")),
                        ],
                        onChanged: (value) => dialogSetState(() => selectedStatus = value!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    await _saveRegistration(registration);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(registration == null ? "Create" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Admissions Registry",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadData,
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
                        _buildSearchSection(),
                        const SizedBox(height: 25),
                        if (filteredRegistrations.isEmpty)
                          _buildEmptyState()
                        else
                          _buildRegistrationGrid(),
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
            colors: [Color(0xff635BFF), Color(0xff7C6FFF), Color(0xff9F97FF)],
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
                  const Text("New Admissions", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Process registration requests and room allocations.", style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRegistrationDialog(),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text("Add Request"),
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
                        const Text("New Admission Requests", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text("Verify student information and allot rooms for new admissions.", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showRegistrationDialog(),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text("Create Request"),
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
      final columns = isMobile ? 2 : 4;
      final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _kpiCard("Total", "${stats["total"]}", Icons.assignment_outlined, _primary, itemWidth),
          _kpiCard("Pending", "${stats["pending"]}", Icons.hourglass_empty_rounded, _warning, itemWidth),
          _kpiCard("Approved", "${stats["approved"]}", Icons.check_circle_outline_rounded, _success, itemWidth),
          _kpiCard("Rejected", "${stats["rejected"]}", Icons.cancel_outlined, _danger, itemWidth),
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

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (v) => _filterRegistrations(),
        decoration: const InputDecoration(
          hintText: "Search by student name or registration ID...",
          prefixIcon: Icon(Icons.search, color: _primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRegistrationGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      final spacing = 20.0;
      final width = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: filteredRegistrations.map((r) => SizedBox(width: width, child: _registrationCard(r))).toList(),
      );
    });
  }

  Widget _registrationCard(Map<String, dynamic> r) {
    String status = (r["status"] ?? "").toString().toLowerCase();

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
              _buildAvatar(r["name"] ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r["name"] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Reg ID: ${r["regId"] ?? "-"}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.school_outlined, "Course", r["course"] ?? "-"),
          const SizedBox(height: 8),
          _detailRow(Icons.account_balance_outlined, "College", r["college"] ?? "-"),
          const SizedBox(height: 8),
          _detailRow(Icons.hotel_outlined, "Room Preference", "${r["roomType"] ?? "-"} \u2022 ${r["preferredBlock"] ?? "-"}"),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (status == "pending") ...[
                TextButton(
                  onPressed: () => _rejectRequest(r["_id"]),
                  style: TextButton.styleFrom(foregroundColor: _danger),
                  child: const Text("Reject"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveRequest(r["_id"]),
                  style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white, elevation: 0),
                  child: const Text("Approve"),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: () => _showRegistrationDialog(registration: r),
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                tooltip: "Edit",
              ),
              IconButton(
                onPressed: () => _deleteRegistration(r["_id"]),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
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

  Widget _statusChip(String status) {
    Color color = status == "approved" ? _success : (status == "rejected" ? _danger : _warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.assignment_ind_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No registration requests found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}
