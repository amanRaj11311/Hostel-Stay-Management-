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

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
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

      // FIX: Normalize the status to lowercase and ensure it matches one of the allowed values
      String status =
          registration["status"]?.toString().toLowerCase() ?? "pending";
      // Map to ensure it's one of the allowed values
      if (status == "approved") {
        selectedStatus = "approved";
      } else if (status == "rejected") {
        selectedStatus = "rejected";
      } else {
        selectedStatus = "pending";
      }

      // FIX: Ensure room type matches exactly
      String roomType = registration["roomType"]?.toString() ?? "AC";
      if (roomType == "Non AC" ||
          roomType == "non ac" ||
          roomType == "non-ac") {
        selectedRoomType = "Non AC";
      } else {
        selectedRoomType = "AC";
      }

      // FIX: Ensure block matches exactly
      String block =
          registration["preferredBlock"]?.toString().toUpperCase() ?? "Block A";
      if (block == "Block B") {
        selectedBlock = "Block B";
      } else if (block == "Block C") {
        selectedBlock = "Block C";
      } else {
        selectedBlock = "Block A";
      }

      print(registration);
      print("RoomType = $selectedRoomType");
      print("Block = $selectedBlock");
      print("Status = $selectedStatus");

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: Text(
                registration == null
                    ? "Create Registration"
                    : "Edit Registration",
              ),

              content: SizedBox(
                width: 700,

                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(regIdController, "Registration ID"),

                      _field(nameController, "Student Name"),

                      _field(emailController, "Email"),

                      _field(phoneController, "Phone"),

                      _field(parentPhoneController, "Parent Phone"),

                      _field(bloodGroupController, "Blood Group"),

                      _field(rollNoController, "Roll No"),

                      _field(courseController, "Course"),

                      _field(yearSemController, "Year / Semester"),

                      _field(collegeController, "College"),

                      _field(addressController, "Address", maxLines: 3),

                      DropdownButtonFormField<String>(
                        value: selectedRoomType,
                        decoration: const InputDecoration(
                          labelText: "Room Type",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "AC", child: Text("AC")),
                          DropdownMenuItem(
                            value: "Non AC",
                            child: Text("Non AC"),
                          ),
                        ],
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedRoomType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedBlock,
                        decoration: const InputDecoration(
                          labelText: "Preferred Block",
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

                      _field(durationController, "Duration"),

                      _field(adminNoteController, "Admin Note", maxLines: 3),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Check In Date"),
                        subtitle: Text(
                          selectedCheckInDate == null
                              ? "Select Date"
                              : "${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}",
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedCheckInDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );

                          if (date != null) {
                            dialogSetState(() {
                              selectedCheckInDate = date;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedStatus.isNotEmpty
                            ? selectedStatus
                            : null, // Add this check
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "pending",
                            child: Text("Pending"),
                          ),
                          DropdownMenuItem(
                            value: "approved",
                            child: Text("Approved"),
                          ),
                          DropdownMenuItem(
                            value: "rejected",
                            child: Text("Rejected"),
                          ),
                        ],
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
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
                    await _saveRegistration(registration);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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
        "checkInDate": (selectedCheckInDate ?? DateTime.now())
            .toIso8601String(),
        "duration": durationController.text.trim(),
        "status": selectedStatus,
        "documents": {},
        "adminNote": adminNoteController.text.trim(),
      };

      if (registration == null) {
        /// CREATE
        await RegistrationService.createRegistration(body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Created Successfully")),
        );
      } else {
        /// UPDATE
        await RegistrationService.updateRegistration(registration["_id"], body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Updated Successfully")),
        );
      }

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
        isLoading = true;
      });

      final response = await RegistrationService.getRegistrations();

      print("STATUS RESPONSE: $response");
      print("DATA: ${response["data"]}");

      setState(() {
        registrations = response["data"] ?? [];
        filteredRegistrations = List.from(registrations);
        isLoading = false;
      });

      print("TOTAL REGISTRATIONS: ${registrations.length}");
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void searchRegistration(String value) {
    setState(() {
      if (value.isEmpty) {
        filteredRegistrations = List.from(registrations);
      } else {
        filteredRegistrations = registrations.where((r) {
          final name = (r["name"] ?? "").toString().toLowerCase();

          return name.contains(value.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteRegistration(String id) async {
    try {
      await RegistrationService.deleteRegistration(id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration Deleted")));

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Registration Requests",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    /// Header
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Registration Requests",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Verify student information and allot rooms for new admissions.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          // <-- REMOVED Expanded
                          onPressed: () {
                            _showRegistrationDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Registration"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: searchController,
                      onChanged: searchRegistration,
                      decoration: InputDecoration(
                        hintText: "Search student...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRegistrations.length,
                      itemBuilder: (context, index) {
                        return _registrationCard(filteredRegistrations[index]);
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statusChip(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "approved":
        color = Colors.green;
        break;

      case "rejected":
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _registrationCard(Map<String, dynamic> registration) {
    Color statusColor;

    switch ((registration["status"] ?? "").toLowerCase()) {
      case "approved":
        statusColor = Colors.green;
        break;
      case "rejected":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

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
                    (registration["name"] ?? "S")
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
                        registration["name"] ?? "-",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text("Reg ID : ${registration["regId"] ?? "-"}"),

                      Text(registration["phone"] ?? "-"),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    registration["status"] ?? "-",
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
                    Icons.school,
                    "Course",
                    registration["course"] ?? "-",
                  ),
                ),

                Expanded(
                  child: _detailTile(
                    Icons.account_balance,
                    "College",
                    registration["college"] ?? "-",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _detailTile(
                    Icons.hotel,
                    "Room Type",
                    registration["roomType"] ?? "-",
                  ),
                ),

                Expanded(
                  child: _detailTile(
                    Icons.location_city,
                    "Block",
                    registration["preferredBlock"] ?? "-",
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showRegistrationDialog(registration: registration);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: () {
                    _deleteRegistration(registration["_id"]);
                  },
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

  Widget _detailTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 18),

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
}
