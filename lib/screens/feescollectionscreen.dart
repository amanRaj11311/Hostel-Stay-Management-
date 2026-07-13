import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/fee_service.dart';
import '../api/resident_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class FeesCollectionScreen extends StatefulWidget {
  const FeesCollectionScreen({super.key});

  @override
  State<FeesCollectionScreen> createState() => _FeesCollectionScreenState();
}

class _FeesCollectionScreenState extends State<FeesCollectionScreen> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> filteredFees = [];
  List<Map<String, dynamic>> residents = [];
  Map<String, dynamic> feeStats = {
    "totalRecords": 0,
    "totalCollected": 0,
    "pendingDues": 0,
    "paidRecords": 0,
  };

  String selectedFilterStatus = "All";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        loadFees(),
        loadResidents(),
      ]);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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

  Future<void> loadFees() async {
    try {
      final response = await FeeService.getFees();
      final stats = await FeeService.getFeeStats();

      if (mounted) {
        setState(() {
          final data = response["data"];
          fees = data is List 
              ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
          _applyFilters();
          
          final statList = List<Map<String, dynamic>>.from(stats["data"] ?? []);
          double totalCollected = 0;
          double pendingDues = 0;
          int paidRecords = fees.where((e) => e["status"] == "paid").length;

          for (var item in statList) {
            if (item["_id"] == "paid") {
              totalCollected = (item["collectedAmount"] ?? 0).toDouble();
            }
            if (item["_id"] == "overdue" || item["_id"] == "pending") {
              pendingDues += (item["totalAmount"] ?? 0).toDouble();
            }
          }

          feeStats = {
            "totalRecords": fees.length,
            "totalCollected": totalCollected,
            "pendingDues": pendingDues,
            "paidRecords": paidRecords,
          };
        });
      }
    } catch (e) {
      debugPrint("Error loading fees: $e");
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredFees = fees.where((fee) {
        final name = (fee["studentName"] ?? "").toString().toLowerCase();
        final room = (fee["roomNo"] ?? "").toString().toLowerCase();
        final month = (fee["month"] ?? "").toString().toLowerCase();
        final id = (fee["residentId"] is Map 
            ? fee["residentId"]["residentId"] ?? "" 
            : fee["residentId"] ?? "").toString().toLowerCase();
        
        bool matchSearch = name.contains(query) || room.contains(query) || month.contains(query) || id.contains(query);
        bool matchStatus = selectedFilterStatus == "All" || fee["status"] == selectedFilterStatus.toLowerCase();
        
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Future<void> _markPaid(String id) async {
    try {
      await FeeService.markFeePaid(id, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fee marked as paid successfully"), behavior: SnackBarBehavior.floating),
        );
        loadFees();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _deleteFee(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to delete this fee record? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FeeService.deleteFee(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted"), behavior: SnackBarBehavior.floating));
          loadFees();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Fee Collection",
      body: Container(
        color: const Color(0xffF6F8FC),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : PullToRefresh(
                onRefresh: loadFees,
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
                          if (filteredFees.isEmpty)
                            const _EmptyFeesState()
                          else
                            _buildFeesGrid(),
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
          colors: [Color(0xff059669), Color(0xff10B981), Color(0xff34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff10B981).withOpacity(.2),
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
                  "Finance Management",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Track student payments, manage monthly dues, and view collection summaries.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showFeeDialog(),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text("New Payment"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff059669),
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
        childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 1.8,
        children: [
          _buildKpiCard("Total Collected", "₹${feeStats["totalCollected"]}", Icons.account_balance_wallet_rounded, const Color(0xff10B981)),
          _buildKpiCard("Pending Dues", "₹${feeStats["pendingDues"]}", Icons.pending_actions_rounded, const Color(0xffEF4444)),
          _buildKpiCard("Paid Records", "${feeStats["paidRecords"]}", Icons.check_circle_rounded, const Color(0xff2563EB)),
          _buildKpiCard("Total Records", "${feeStats["totalRecords"]}", Icons.receipt_long_rounded, const Color(0xff6366F1)),
        ],
      );
    });
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title, 
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
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
        hintText: "Search student, room, month or ID...",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xff10B981)),
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
          DropdownMenuItem(value: "paid", child: Text("Paid")),
          DropdownMenuItem(value: "pending", child: Text("Pending")),
          DropdownMenuItem(value: "partial", child: Text("Partial")),
          DropdownMenuItem(value: "overdue", child: Text("Overdue")),
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

  Widget _buildFeesGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: filteredFees.map((fee) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
            child: FeeCard(
              fee: fee,
              onMarkPaid: () => _markPaid(fee["_id"]),
              onDelete: () => _deleteFee(fee["_id"]),
              onEdit: () => _showFeeDialog(fee: fee),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showFeeDialog({Map<String, dynamic>? fee}) {
    showDialog(
      context: context,
      builder: (context) => FeeFormDialog(
        fee: fee,
        residents: residents,
        onSaved: loadFees,
      ),
    );
  }
}

class FeeCard extends StatelessWidget {
  final Map<String, dynamic> fee;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const FeeCard({
    super.key,
    required this.fee,
    required this.onMarkPaid,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = (fee["status"] ?? "pending").toString().toLowerCase();
    final Color statusColor = status == "paid"
        ? const Color(0xff10B981)
        : status == "partial"
            ? const Color(0xffF59E0B)
            : const Color(0xffEF4444);

    final residentId = fee["residentId"] is Map 
        ? fee["residentId"]["residentId"] ?? "-" 
        : fee["residentId"]?.toString() ?? "-";

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
              _buildAvatar(fee["studentName"] ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fee["studentName"] ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("ID: $residentId", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              _StatusBadge(status: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _IconInfoItem(icon: Icons.meeting_room_rounded, label: "Room ${fee["roomNo"] ?? "-"}"),
              const SizedBox(width: 12),
              _IconInfoItem(icon: Icons.calendar_today_rounded, label: fee["month"] ?? "-"),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xffF9FAFB), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildDataRow("Total Amount", "₹${fee["amount"]}", isBoldValue: true),
                const SizedBox(height: 8),
                _buildDataRow("Paid Amount", "₹${fee["paidAmount"]}", valueColor: const Color(0xff10B981)),
                const SizedBox(height: 8),
                _buildDataRow("Due Date", _formatDate(fee["dueDate"])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "Mode: ${fee["paymentMode"]?.toString().toUpperCase() ?? "-"}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (status != "paid")
                IconButton(
                  onPressed: onMarkPaid,
                  icon: const Icon(Icons.check_circle_rounded, color: Color(0xff10B981)),
                  tooltip: "Mark as Paid",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),
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
        gradient: const LinearGradient(colors: [Color(0xff059669), Color(0xff34D399)]),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isBoldValue = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600, fontSize: 13, color: valueColor)),
      ],
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.blue), SizedBox(width: 10), Text("Edit")])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))])),
      ],
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    try {
      final d = DateTime.parse(date.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return date.toString().split("T").first;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _IconInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class FeeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? fee;
  final List<Map<String, dynamic>> residents;
  final VoidCallback onSaved;

  const FeeFormDialog({super.key, this.fee, required this.residents, required this.onSaved});

  @override
  State<FeeFormDialog> createState() => _FeeFormDialogState();
}

class _FeeFormDialogState extends State<FeeFormDialog> {
  final amountController = TextEditingController();
  final paidAmountController = TextEditingController();
  final receiptNoController = TextEditingController();
  final monthController = TextEditingController();
  
  String? selectedResidentId;
  String? selectedStudentName;
  String? selectedRoomNo;
  String status = "paid";
  String paymentMode = "cash";
  DateTime dueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.fee != null) {
      final res = widget.fee!["residentId"];
      selectedResidentId = res is Map ? res["_id"]?.toString() : res?.toString();
      selectedStudentName = widget.fee!["studentName"];
      selectedRoomNo = widget.fee!["roomNo"];
      amountController.text = (widget.fee!["amount"] ?? "").toString();
      paidAmountController.text = (widget.fee!["paidAmount"] ?? "").toString();
      receiptNoController.text = widget.fee!["receiptNo"] ?? "";
      monthController.text = widget.fee!["month"] ?? "";
      status = widget.fee!["status"] ?? "paid";
      paymentMode = widget.fee!["paymentMode"] ?? "cash";
      if (widget.fee!["dueDate"] != null) {
        dueDate = DateTime.parse(widget.fee!["dueDate"]);
      }
    }
  }

  Future<void> _handleSave() async {
    if (selectedResidentId == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resident and Amount are required"), behavior: SnackBarBehavior.floating));
      return;
    }

    final body = {
      "residentId": selectedResidentId,
      "studentName": selectedStudentName,
      "roomNo": selectedRoomNo,
      "amount": double.tryParse(amountController.text) ?? 0,
      "paidAmount": double.tryParse(paidAmountController.text) ?? 0,
      "receiptNo": receiptNoController.text.trim(),
      "month": monthController.text.trim(),
      "status": status,
      "paymentMode": paymentMode,
      "dueDate": dueDate.toIso8601String(),
    };

    try {
      if (widget.fee == null) {
        await FeeService.createFee(body);
      } else {
        await FeeService.updateFee(widget.fee!["_id"], body);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving fee: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.fee != null;

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
                  Icon(isEditing ? Icons.edit_calendar_rounded : Icons.add_card_rounded, color: const Color(0xff059669), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? "Edit Fee Record" : "Collect New Fee", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                    _buildLabel("Resident *"),
                    DropdownButtonFormField<String>(
                      value: selectedResidentId,
                      isExpanded: true,
                      hint: const Text("Select Resident"),
                      decoration: _buildInputDecoration("Search resident..."),
                      items: widget.residents.isEmpty 
                        ? []
                        : widget.residents.map<DropdownMenuItem<String>>((r) {
                            final String name = r["name"]?.toString() ?? "Unknown";
                            final String regId = r["residentId"]?.toString() ?? "-";
                            final String id = r["_id"]?.toString() ?? "";
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text("$name ($regId)"),
                            );
                          }).toList(),
                      onChanged: (val) {
                        final res = widget.residents.firstWhere((element) => element["_id"].toString() == val);
                        setState(() {
                          selectedResidentId = val;
                          selectedStudentName = res["name"];
                          selectedRoomNo = res["roomNo"];
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Amount *", amountController, "0.00", keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Paid Amount", paidAmountController, "0.00", keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Billing Month", monthController, "e.g. Oct 2023")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Receipt No", receiptNoController, "REC-001")),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildDropdownField("Status", status, ["paid", "pending", "partial", "overdue"], (val) => setState(() => status = val!))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdownField("Payment Mode", paymentMode, ["cash", "upi", "bank"], (val) => setState(() => paymentMode = val!))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Due Date"),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (date != null) setState(() => dueDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${dueDate.day}/${dueDate.month}/${dueDate.year}"),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xff059669)),
                          ],
                        ),
                      ),
                    ),
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
                      backgroundColor: const Color(0xff059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? "Update Record" : "Collect Payment"),
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

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextField(controller: controller, keyboardType: keyboardType, decoration: _buildInputDecoration(hint)),
      ],
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff059669), width: 1.5)),
    );
  }
}

class _EmptyFeesState extends StatelessWidget {
  const _EmptyFeesState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No Fee Records Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Try changing your search or status filter to find records.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
