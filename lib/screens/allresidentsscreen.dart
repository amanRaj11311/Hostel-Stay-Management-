import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/resident_service.dart';
import 'responsive.dart';

import 'pull_to_refresh.dart';

class AllresidentSscreen extends StatefulWidget {
  const AllresidentSscreen({super.key});

  @override
  State<AllresidentSscreen> createState() => _AllresidentSscreenState();
}

class _AllresidentSscreenState extends State<AllresidentSscreen> {
  final TextEditingController searchController = TextEditingController();

  final residentIdController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final rollNoController = TextEditingController();
  final courseController = TextEditingController();
  final collegeController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final addressController = TextEditingController();
  final roomNoController = TextEditingController();
  final bedNoController = TextEditingController();
  bool isActive = true;

  String selectedFeeStatus = "paid";
  String selectedAttendance = "present";

  DateTime? selectedCheckInDate = DateTime.now();
  DateTime? selectedCheckOutDate = DateTime.now();

  bool isLoading = true;

  List residents = [];

  List filteredResidents = [];

  String selectedBlock = "All Blocks";
  String selectedStatus = "All Status";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void _showResidentDialog({Map<String, dynamic>? resident}) {
    if (resident != null) {
      residentIdController.text = resident["residentId"] ?? "";
      nameController.text = resident["name"] ?? "";
      emailController.text = resident["email"] ?? "";
      phoneController.text = resident["phone"] ?? "";
      parentPhoneController.text = resident["parentPhone"] ?? "";
      rollNoController.text = resident["rollNo"] ?? "";
      courseController.text = resident["course"] ?? "";
      collegeController.text = resident["college"] ?? "";
      bloodGroupController.text = resident["bloodGroup"] ?? "";
      addressController.text = resident["address"] ?? "";
      roomNoController.text = resident["roomNo"] ?? "";
      bedNoController.text = resident["bedNo"] ?? "";

      selectedBlock = resident["block"] ?? "Block A";

      selectedFeeStatus = resident["feeStatus"] ?? "paid";
      selectedAttendance = resident["attendanceStatus"] ?? "present";

      isActive = resident["isActive"] ?? true;

      selectedCheckInDate = resident["checkInDate"] == null
          ? DateTime.now()
          : DateTime.parse(resident["checkInDate"]);

      selectedCheckOutDate = resident["checkOutDate"] == null
          ? DateTime.now()
          : DateTime.parse(resident["checkOutDate"]);
    } else {
      residentIdController.clear();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      parentPhoneController.clear();
      rollNoController.clear();
      courseController.clear();
      collegeController.clear();
      bloodGroupController.clear();
      addressController.clear();
      roomNoController.clear();
      bedNoController.clear();

      selectedBlock = "Block A";

      selectedFeeStatus = "paid";
      selectedAttendance = "present";

      isActive = true;

      selectedCheckInDate = DateTime.now();
      selectedCheckOutDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(resident == null ? "Add Resident" : "Edit Resident"),

              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(residentIdController, "Resident ID"),

                      _field(nameController, "Name"),

                      _field(emailController, "Email"),

                      _field(phoneController, "Phone"),

                      _field(parentPhoneController, "Parent Phone"),

                      _field(rollNoController, "Roll No"),

                      _field(courseController, "Course"),

                      _field(collegeController, "College"),

                      _field(bloodGroupController, "Blood Group"),

                      _field(addressController, "Address", maxLines: 3),

                      _field(roomNoController, "Room No"),

                      _field(bedNoController, "Bed No"),
                      DropdownButtonFormField<String>(
                        value: selectedBlock,
                        decoration: const InputDecoration(
                          labelText: "Block",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Block A",
                            child: Text("Block A"),
                          ),
                          DropdownMenuItem(
                            value: "Block B",
                            child: Text("Block B"),
                          ),
                          DropdownMenuItem(
                            value: "Block C",
                            child: Text("Block C"),
                          ),
                        ],
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedBlock = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    await _saveResident(resident);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(resident == null ? "Create" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await ResidentService.getResidents();

      print(response);

      setState(() {
        residents = response["data"] ?? [];

        filteredResidents = List.from(residents);

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

  Future<void> searchResidents(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        filteredResidents = List.from(residents);
      });
      return;
    }

    try {
      final response = await ResidentService.searchResidents(value);

      setState(() {
        filteredResidents = response["data"] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void searchResident(String value) {
    setState(() {
      if (value.isEmpty) {
        filteredResidents = List.from(residents);
      } else {
        filteredResidents = residents.where((resident) {
          final name = (resident["name"] ?? "").toString().toLowerCase();

          final room = (resident["roomNo"] ?? "").toString().toLowerCase();

          final id = (resident["residentId"] ?? "").toString().toLowerCase();

          return name.contains(value.toLowerCase()) ||
              room.contains(value.toLowerCase()) ||
              id.contains(value.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteResident(String id) async {
    try {
      await ResidentService.deleteResident(id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Resident Deleted Successfully")),
      );

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmDelete(Map<String, dynamic> resident) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Resident"),

          content: Text("Are you sure you want to delete ${resident["name"]}?"),

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

                await _deleteResident(resident["_id"]);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAttendance(String id, String status) async {
    try {
      await ResidentService.updateAttendance(id, {"attendanceStatus": status});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attendance Updated")));

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _updateFeeStatus(String id, String status) async {
    try {
      await ResidentService.updateFeeStatus(id, {"feeStatus": status});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fee Status Updated")));

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveResident(Map<String, dynamic>? resident) async {
    try {
      final body = {
        "residentId": residentIdController.text.trim(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "parentPhone": parentPhoneController.text.trim(),
        "rollNo": rollNoController.text.trim(),
        "course": courseController.text.trim(),
        "college": collegeController.text.trim(),
        "bloodGroup": bloodGroupController.text.trim(),
        "address": addressController.text.trim(),
        "block": selectedBlock,
        "roomNo": roomNoController.text.trim(),
        "bedNo": bedNoController.text.trim(),
        "checkInDate": selectedCheckInDate?.toIso8601String(),
        "checkOutDate": selectedCheckOutDate?.toIso8601String(),
        "feeStatus": selectedFeeStatus,
        "attendanceStatus": selectedAttendance,
        "isActive": isActive,
      };

      if (resident == null) {
        await ResidentService.createResident(body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resident Created Successfully")),
        );
      } else {
        await ResidentService.updateResident(resident["_id"], body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resident Updated Successfully")),
        );
      }

      await loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showResidentDetails(Map<String, dynamic> resident) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            resident["name"] ?? "Resident Details",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail("Resident ID", resident["residentId"]),
                  _detail("Email", resident["email"]),
                  _detail("Phone", resident["phone"]),
                  _detail("Parent Phone", resident["parentPhone"]),
                  _detail("Roll No", resident["rollNo"]),
                  _detail("Course", resident["course"]),
                  _detail("College", resident["college"]),
                  _detail("Blood Group", resident["bloodGroup"]),
                  _detail("Address", resident["address"]),
                  _detail("Block", resident["block"]),
                  _detail("Room", resident["roomNo"]),
                  _detail("Bed", resident["bedNo"]),
                  DropdownButtonFormField<String>(
                    value: resident["feeStatus"] ?? "paid",
                    decoration: const InputDecoration(
                      labelText: "Fee Status",
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
                    ],
                    onChanged: (value) async {
                      if (value == null) return;

                      await _updateFeeStatus(resident["_id"], value);

                      if (context.mounted) {
                        Navigator.pop(context);
                        loadData();
                      }
                    },
                  ),

                  DropdownButtonFormField<String>(
                    value: resident["attendanceStatus"] ?? "present",
                    decoration: const InputDecoration(
                      labelText: "Attendance",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "present",
                        child: Text("Present"),
                      ),
                      DropdownMenuItem(
                        value: "outside",
                        child: Text("Outside"),
                      ),
                      DropdownMenuItem(value: "leave", child: Text("Leave")),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;

                      await _updateAttendance(resident["_id"], value);

                      if (context.mounted) {
                        Navigator.pop(context);
                        loadData();
                      }
                    },
                  ),

                  _detail("Active", "${resident["isActive"]}"),
                  _detail("Check In", resident["checkInDate"]),
                  _detail("Check Out", resident["checkOutDate"]),
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
                _showResidentDialog(resident: resident);
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
                _confirmDelete(resident);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "All Residents",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),

                    const SizedBox(height: 20),

                    _filterCard(),

                    const SizedBox(height: 24),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredResidents.length,

                      itemBuilder: (context, index) {
                        print("Total Residents: ${filteredResidents.length}");
                        return _residentCard(filteredResidents[index]);
                      },


                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _header() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "All Residents",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Manage active hostelers, track rooms, occupancy, and live status.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
        SizedBox(height: 7),

        ElevatedButton.icon(
          onPressed: () {
            _showResidentDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Resident"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff5668F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Search Box
          TextField(
            controller: searchController,
            onChanged: searchResidents,
            decoration: InputDecoration(
              hintText: "Search by name, room number, id...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// Dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedBlock,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "All Blocks",
                      child: Text("All Blocks"),
                    ),
                    DropdownMenuItem(value: "Block A", child: Text("Block A")),
                    DropdownMenuItem(value: "Block B", child: Text("Block B")),
                    DropdownMenuItem(value: "Block C", child: Text("Block C")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedBlock = v!;
                    });
                  },
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "All Status",
                      child: Text("All Status"),
                    ),
                    DropdownMenuItem(value: "Present", child: Text("Present")),
                    DropdownMenuItem(value: "Outside", child: Text("Outside")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedStatus = v!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _residentCard(Map<String, dynamic> resident) {
     print(resident["name"]);
    final status = resident["attendanceStatus"] ?? "present";

    Color statusColor;

    if (status == "present") {
      statusColor = Colors.green;
    } else if (status == "outside") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (resident["name"] ?? "S")
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
                        resident["name"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      Text(
                        resident["residentId"] ?? "",
                        style: const TextStyle(color: Colors.grey),
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
                    status.toUpperCase(),
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
                  child: _infoTile(
                    Icons.meeting_room,
                    "Room",
                    "${resident["block"]} - ${resident["roomNo"]}",
                  ),
                ),

                Expanded(
                  child: _infoTile(Icons.bed, "Bed", resident["bedNo"] ?? "-"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    Icons.school,
                    "Course",
                    resident["course"] ?? "-",
                  ),
                ),

                Expanded(
                  child: _infoTile(
                    Icons.account_balance,
                    "College",
                    resident["college"] ?? "-",
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showResidentDetails(resident);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("View"),
                ),

                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: () {
                    _showResidentDialog(resident: resident);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),

                const SizedBox(width: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    _confirmDelete(resident);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _residentRow(Map<String, dynamic> resident) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          /// Resident
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (resident["name"] ?? "S")
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resident["name"] ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        resident["residentId"] ?? "-",
                        style: TextStyle(color: Colors.grey.shade600),
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
                  "${resident["block"] ?? "-"}, ${resident["roomNo"] ?? "-"}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text("-"),
              ],
            ),
          ),

          /// Academic
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resident["course"] ?? "-"),
                const SizedBox(height: 4),
                Text(
                  resident["college"] ?? "-",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          /// Live Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.12),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 4, backgroundColor: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    resident["attendanceStatus"] ?? "present",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Arrow
          Expanded(
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                size: 28,
                color: Colors.grey,
              ),
              onPressed: () {
                _showResidentDetails(resident);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.indigo),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
