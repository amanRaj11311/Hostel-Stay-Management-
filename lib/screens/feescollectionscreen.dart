import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/fee_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class FeesCollectionScreen extends StatefulWidget {
  const FeesCollectionScreen({super.key});

  @override
  State<FeesCollectionScreen> createState() => _FeesCollectionScreenState();
}

class _FeesCollectionScreenState extends State<FeesCollectionScreen> {
  final TextEditingController searchController = TextEditingController();

  final residentIdController = TextEditingController();
  final studentNameController = TextEditingController();
  final roomNoController = TextEditingController();
  final monthController = TextEditingController();
  final amountController = TextEditingController();
  final paidAmountController = TextEditingController();
  final receiptNoController = TextEditingController();

  String selectedStatus = "All";

  String feeStatus = "paid";

  String paymentMode = "cash";

  DateTime? dueDate = DateTime.now();

  DateTime? paidDate = DateTime.now();

  bool isLoading = false;

  List fees = [];

  List filteredFees = [];
  Map<String, dynamic> feeStats = {};

  @override
  void initState() {
    super.initState();
    loadFees();
  }

  Future<void> _saveFee(Map<String, dynamic>? fee) async {
    try {
      final body = {
        "residentId": residentIdController.text.trim(),
        "studentName": studentNameController.text.trim(),
        "roomNo": roomNoController.text.trim(),
        "month": monthController.text.trim(),
        "amount": double.tryParse(amountController.text) ?? 0,
        "paidAmount": double.tryParse(paidAmountController.text) ?? 0,
        "dueDate": dueDate?.toIso8601String(),
        "paidDate": paidDate?.toIso8601String(),
        "status": feeStatus,
        "paymentMode": paymentMode,
        "receiptNo": receiptNoController.text.trim(),
      };

      if (fee == null) {
        await FeeService.createFee(body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fee Record Created Successfully")),
        );
      } else {
        await FeeService.updateFee(fee["_id"], body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fee Record Updated Successfully")),
        );
      }

      await loadFees();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadFees() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await FeeService.getFees();
      print("Fees API => $response");

      final stats = await FeeService.getFeeStats();
      print("Stats API => $stats");
      print(response);
      print(response["data"]);
      print(response["data"][0]);

      setState(() {
        fees = response["data"] ?? [];
        filteredFees = List.from(fees);
        final statList = List<Map<String, dynamic>>.from(stats["data"] ?? []);

        double totalCollected = 0;
        double pendingDues = 0;
        int paidRecords = 0;

        for (var item in statList) {
          if (item["_id"] == "paid") {
            totalCollected = (item["collectedAmount"] ?? 0).toDouble();
            paidRecords = fees.where((e) => e["status"] == "paid").length;
          }

          if (item["_id"] == "overdue") {
            pendingDues = (item["totalAmount"] ?? 0).toDouble();
          }
        }

        setState(() {
          fees = response["data"] ?? [];
          filteredFees = List.from(fees);

          feeStats = {
            "totalRecords": fees.length,
            "totalCollected": totalCollected,
            "pendingDues": pendingDues,
            "paidRecords": paidRecords,
          };

          isLoading = false;
        });

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _markPaid(String id) async {
    try {
      await FeeService.markFeePaid(id, {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fee Marked as Paid Successfully")),
      );

      loadFees();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmMarkPaid(Map<String, dynamic> fee) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Mark Paid"),

          content: Text("Mark fee of ${fee["studentName"]} as Paid?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await _markPaid(fee["_id"]);
              },

              child: const Text("Mark Paid"),
            ),
          ],
        );
      },
    );
  }

  void _showFeeDetails(Map<String, dynamic> fee) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            fee["studentName"] ?? "Fee Details",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail("Resident ID", fee["residentId"]),

                  _detail("Student", fee["studentName"]),

                  _detail("Room", fee["roomNo"]),

                  _detail("Month", fee["month"]),

                  _detail("Amount", "₹${fee["amount"]}"),

                  _detail("Paid", "₹${fee["paidAmount"]}"),

                  _detail("Status", fee["status"]),

                  _detail("Payment Mode", fee["paymentMode"]),

                  _detail("Receipt", fee["receiptNo"]),

                  _detail("Due Date", fee["dueDate"]),

                  _detail("Paid Date", fee["paidDate"]),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit"),
              onPressed: () {
                Navigator.pop(context);

                _showFeeDialog(fee: fee);
              },
            ),
            if (fee["status"] != "paid")
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text("Mark Paid"),
                onPressed: () {
                  Navigator.pop(context);

                  _confirmMarkPaid(fee);
                },
              ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete),
              label: const Text("Delete"),
              onPressed: () {
                Navigator.pop(context);

                _confirmDeleteFee(fee);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFee(String id) async {
    try {
      await FeeService.deleteFee(id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fee Deleted Successfully")));

      loadFees();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmDeleteFee(Map<String, dynamic> fee) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Fee"),

          content: Text("Delete fee record of ${fee["studentName"]} ?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                await _deleteFee(fee["_id"]);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showFeeDialog({Map<String, dynamic>? fee}) {
    if (fee != null) {
      residentIdController.text = fee["residentId"] ?? "";
      studentNameController.text = fee["studentName"] ?? "";
      roomNoController.text = fee["roomNo"] ?? "";
      monthController.text = fee["month"] ?? "";
      amountController.text = (fee["amount"] ?? "").toString();
      paidAmountController.text = (fee["paidAmount"] ?? "").toString();
      receiptNoController.text = fee["receiptNo"] ?? "";

      const validStatus = ["paid", "pending", "partial", "overdue"];

      feeStatus = validStatus.contains(fee["status"]) ? fee["status"] : "paid";

      const validPaymentModes = ["cash", "upi", "bank"];

      paymentMode = validPaymentModes.contains(fee["paymentMode"])
          ? fee["paymentMode"]
          : "cash";

      print("Status from API = ${fee["status"]}");
      print("feeStatus = $feeStatus");

      print("paymentMode = $paymentMode");

      dueDate = fee["dueDate"] == null
          ? DateTime.now()
          : DateTime.parse(fee["dueDate"]);

      paidDate = fee["paidDate"] == null
          ? DateTime.now()
          : DateTime.parse(fee["paidDate"]);
    } else {
      residentIdController.clear();
      studentNameController.clear();
      roomNoController.clear();
      monthController.clear();
      amountController.clear();
      paidAmountController.clear();
      receiptNoController.clear();

      feeStatus = "paid";
      paymentMode = "cash";

      dueDate = DateTime.now();
      paidDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: Text(fee == null ? "Add Fee Record" : "Edit Fee Record"),

              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(residentIdController, "Resident ID"),

                      _field(studentNameController, "Student Name"),

                      _field(roomNoController, "Room Number"),

                      _field(monthController, "Month"),

                      _field(
                        amountController,
                        "Total Amount",
                        keyboardType: TextInputType.number,
                      ),

                      _field(
                        paidAmountController,
                        "Paid Amount",
                        keyboardType: TextInputType.number,
                      ),

                      _field(receiptNoController, "Receipt Number"),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: feeStatus,
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "paid", child: Text("Paid")),

                          DropdownMenuItem(
                            value: "pending",
                            child: Text("Pending"),
                          ),

                          DropdownMenuItem(
                            value: "partial",
                            child: Text("Partial"),
                          ),

                          DropdownMenuItem(
                            value: "overdue",
                            child: Text("Overdue"),
                          ),
                        ],

                        onChanged: (v) {
                          dialogSetState(() {
                            feeStatus = v!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: paymentMode,
                        decoration: const InputDecoration(
                          labelText: "Payment Mode",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "cash", child: Text("Cash")),

                          DropdownMenuItem(value: "upi", child: Text("UPI")),

                          DropdownMenuItem(
                            value: "bank",
                            child: Text("Bank Transfer"),
                          ),
                        ],
                        onChanged: (v) {
                          dialogSetState(() {
                            paymentMode = v!;
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
                  onPressed: () async {
                    await _saveFee(fee);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(fee == null ? "Create" : "Update"),
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
      title: "Fee Management",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadFees,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_header(),
                    const SizedBox(height: 0),

                    _stats(),

                    const SizedBox(height: 15),

                    _searchCard(),

                    const SizedBox(height: 15),

                    _feeTable(),
                  ],
                ),
              ),
            ),
    );
  }

  /*Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Fee Management",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 6),

            Text(
              "Manage student dues, view collections, and process payments.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),

        ElevatedButton.icon(
          onPressed: () {
            _showFeeDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Fee Record"),
        ),
      ],
    );
  }*/

  Widget _stats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // int crossAxisCount = constraints.maxWidth < 700 ? 2 : 4;
        bool mobile = constraints.maxWidth < 700;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: mobile ? 2 : 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: mobile ? 1.2 : 2.4,
          children: [
            _statCard(
              "Total Records",
              "${feeStats["totalRecords"] ?? 0}",
              Icons.receipt_long,
              Colors.blue,
            ),

            _statCard(
              "Total Collected",
              "₹${feeStats["totalCollected"] ?? 0}",
              Icons.currency_rupee,
              Colors.green,
            ),

            _statCard(
              "Pending Dues",
              "₹${feeStats["pendingDues"] ?? 0}",
              Icons.warning_amber_rounded,
              Colors.orange,
            ),

            _statCard(
              "Paid Records",
              "${feeStats["paidRecords"] ?? 0}",
              Icons.check_circle,
              Colors.teal,
            ),
          ],
        );
      },
    );
  }

  //_statCard
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
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
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by name, ID, room no...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "All", child: Text("All")),
                DropdownMenuItem(value: "paid", child: Text("Paid")),
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "partial", child: Text("Partial")),
                DropdownMenuItem(value: "overdue", child: Text("Overdue")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredFees.length,
      itemBuilder: (context, index) {
        return _feeCard(filteredFees[index]);
      },
    );
  }

  Widget _feeCard(Map<String, dynamic> fee) {
    final Color statusColor = fee["status"] == "paid"
        ? Colors.green
        : fee["status"] == "partial"
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Student
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (fee["studentName"] ?? "S")
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
                        fee["studentName"] ?? "-",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "Resident ID : ${fee["residentId"] is Map ? fee["residentId"]["residentId"] ?? "-" : fee["residentId"] ?? "-"}",
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fee["status"] ?? "",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _detailTile(
                    Icons.meeting_room,
                    "Room",
                    fee["roomNo"] ?? "-",
                  ),
                ),

                Expanded(
                  child: _detailTile(
                    Icons.calendar_month,
                    "Month",
                    fee["month"] ?? "-",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _detailTile(
                    Icons.currency_rupee,
                    "Amount",
                    "₹${fee["amount"]}",
                  ),
                ),

                Expanded(
                  child: _detailTile(
                    Icons.payments,
                    "Paid",
                    "₹${fee["paidAmount"]}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _detailTile(
                    Icons.event,
                    "Due Date",
                    fee["dueDate"] == null
                        ? "-"
                        : fee["dueDate"].toString().split("T").first,
                  ),
                ),

                Expanded(
                  child: _detailTile(
                    Icons.receipt,
                    "Receipt",
                    fee["receiptNo"] ?? "-",
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (fee["status"] != "paid")
                  ElevatedButton.icon(
                    onPressed: () => _confirmMarkPaid(fee),
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Mark Paid"),
                  ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: () => _showFeeDialog(fee: fee),
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteFee(fee),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _feeRow(Map<String, dynamic> fee) {
    print(fee);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          /// Student
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (fee["studentName"] ?? "S")
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee["studentName"] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        fee["residentId"] is Map
                            ? fee["residentId"]["residentId"] ?? "-"
                            : fee["residentId"]?.toString() ?? "-",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Room
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee["course"] is Map
                      ? fee["course"]["name"] ?? "-"
                      : fee["course"]?.toString() ?? "-",
                ),

                const SizedBox(height: 4),

                Text(
                  fee["roomNo"] ?? "-",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          /// Month
          Expanded(flex: 2, child: Text(fee["month"] ?? "-")),

          /// Amount
          Expanded(
            flex: 3,
            child: Text(
              "₹${fee["paidAmount"]} / ₹${fee["amount"]}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          /// Due Date
          Expanded(
            flex: 2,
            child: Text(
              fee["dueDate"] == null
                  ? "-"
                  : fee["dueDate"].toString().split("T").first,
            ),
          ),

          /// Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: fee["status"] == "paid"
                    ? Colors.green.withOpacity(.15)
                    : fee["status"] == "partial"
                    ? Colors.orange.withOpacity(.15)
                    : Colors.red.withOpacity(.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  fee["status"] ?? "-",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fee["status"] == "paid"
                        ? Colors.green
                        : fee["status"] == "partial"
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
            ),
          ),

          /// Action
          Expanded(
            child: IconButton(
              onPressed: () {
                _showFeeDetails(fee);
              },
              icon: const Icon(
                Icons.chevron_right,
                size: 28,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value?.toString() ?? "-")),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
