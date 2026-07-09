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

      selectedStatus = registration["status"] ?? "pending";

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
                        value: selectedStatus,

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
  "checkInDate":
      (selectedCheckInDate ?? DateTime.now())
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
                    SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: SizedBox(
    width: 1300, // ya 1400
    child:

                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          /// Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    "STUDENT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "COURSE",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "ROOM TYPE",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "STATUS",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "ACTIONS",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRegistrations.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final item = filteredRegistrations[index];

                              return _registrationRow(item);
                            },
                          ),
                        ],
                      ),
                    ),)),

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

  Widget _registrationRow(Map<String, dynamic> registration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          /// Student
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Text(
                        "Reg ID : ${registration["regId"] ?? "-"}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),

                      Text(
                        registration["phone"] ?? "",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Course
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registration["course"] ?? "-"),

                Text(
                  registration["college"] ?? "-",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
      Text(registration["roomType"] ?? "-"),
      Text(
        registration["preferredBlock"] ?? "-",
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
    ],
  ),
),

          /// Status
          Expanded(
            flex: 2,
            child: _statusChip(registration["status"] ?? "pending"),
          ),

          /// Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  tooltip: "Edit",
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showRegistrationDialog(registration: registration);
                  },
                ),

                IconButton(
                  tooltip: "Delete",
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteRegistration(registration["_id"]);
                  },
                ),
              ],
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
}
