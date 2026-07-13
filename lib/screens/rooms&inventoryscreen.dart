import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/room_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class RoomsAndInventoryscreen extends StatefulWidget {
  const RoomsAndInventoryscreen({super.key});

  @override
  State<RoomsAndInventoryscreen> createState() =>
      _RoomsAndInventoryscreenState();
}

class _RoomsAndInventoryscreenState extends State<RoomsAndInventoryscreen> {
  final TextEditingController roomNumberController = TextEditingController();

  final TextEditingController roomTypeController = TextEditingController();

  final TextEditingController sharingController = TextEditingController();

  final TextEditingController rentController = TextEditingController();

  final TextEditingController capacityController = TextEditingController();

  final TextEditingController floorController = TextEditingController();
  final TextEditingController occupiedController = TextEditingController();

  final TextEditingController bedsController = TextEditingController();
  final TextEditingController fansController = TextEditingController();
  final TextEditingController cupboardController = TextEditingController();
  final TextEditingController studyTableController = TextEditingController();

  final TextEditingController notesController = TextEditingController();

  String selectedBlock = "A";
  String selectedRoomType = "AC";
  String selectedSharing = "2 Sharing";
  bool attachedBathroom = true;
  bool wifiAvailable = true;
  String roomStatus = "available";

  bool isLoading = true;

  List rooms = [];
  List filteredRooms = [];

  Map<String, dynamic> stats = {};

  String selectedFilter = "All";

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();

    roomNumberController.dispose();
    roomTypeController.dispose();
    sharingController.dispose();
    rentController.dispose();
    capacityController.dispose();

    floorController.dispose();
    occupiedController.dispose();

    bedsController.dispose();
    fansController.dispose();
    cupboardController.dispose();
    studyTableController.dispose();

    super.dispose();
  }

  void _showEditRoomDialog(Map room) {
    roomNumberController.text = room["roomNo"]?.toString() ?? "";

    roomTypeController.text = room["roomType"]?.toString() ?? "";

    sharingController.text = room["seating"]?.toString() ?? "";

    capacityController.text = room["totalCapacity"]?.toString() ?? "";

    rentController.text = room["monthlyRent"]?.toString() ?? "";

    roomStatus = room["status"]?.toString() ?? "Available";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Room"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: roomNumberController,
                  decoration: const InputDecoration(labelText: "Room Number"),
                ),

                TextField(
                  controller: roomTypeController,
                  decoration: const InputDecoration(labelText: "Room Type"),
                ),

                TextField(
                  controller: sharingController,
                  decoration: const InputDecoration(labelText: "Sharing"),
                ),

                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Capacity"),
                ),
                DropdownButtonFormField<String>(
                  value: selectedBlock,
                  decoration: const InputDecoration(labelText: "Hostel Block"),
                  items: const [
                    DropdownMenuItem(value: "A", child: Text("Block A")),
                    DropdownMenuItem(value: "B", child: Text("Block B")),
                    DropdownMenuItem(value: "C", child: Text("Block C")),
                    DropdownMenuItem(value: "D", child: Text("Block D")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedBlock = value!;
                    });
                  },
                ),

                TextField(
                  controller: rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Rent"),
                ),

                DropdownButtonFormField<String>(
                  value: roomStatus,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: const [
                    DropdownMenuItem(
                      value: "available",
                      child: Text("Available"),
                    ),
                    DropdownMenuItem(value: "full", child: Text("Full")),
                    DropdownMenuItem(
                      value: "maintenance",
                      child: Text("Maintenance"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      roomStatus = value!;
                    });
                  },
                ),
              ],
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
              onPressed: () {
                _updateRoom(room["_id"].toString());
              },

              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRoom(String id) async {
    try {
      final body = {
        "roomNo": roomNumberController.text,

        "roomType": roomTypeController.text,

        "seating": sharingController.text,

        "totalCapacity": int.tryParse(capacityController.text) ?? 0,

        "monthlyRent": double.tryParse(rentController.text) ?? 0,

        "status": roomStatus,
      };

      await RoomService.updateRoom(id, body);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room Updated Successfully")),
      );

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteRoom(Map room) async {
    bool? confirm = await showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Room"),

          content: Text("Delete Room ${room["roomNo"]} ?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await RoomService.deleteRoom(room["_id"].toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Room Deleted")));

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final roomRes = await RoomService.getRooms();
      final statsRes = await RoomService.getRoomStats();

      print("ROOM RESPONSE: $roomRes");
      print("ROOM DATA: ${roomRes["data"]}");

      print("STATS RESPONSE: $statsRes");
      print("STATS DATA: ${statsRes["data"]}");

      rooms = roomRes["data"] ?? [];
      filteredRooms = List.from(rooms);

      List statsList = statsRes["data"] ?? [];

      int available = 0;
      int occupied = 0;

      for (var item in statsList) {
        if (item["_id"] == "available") {
          available = item["count"] ?? 0;
        }

        if (item["_id"] == "occupied") {
          occupied = item["count"] ?? 0;
        }
      }

      stats = {
        "vacantRooms": available,
        "occupiedRooms": occupied,
        "totalRooms": available + occupied,
        "totalBeds": rooms.fold<int>(
          0,
          (sum, r) => sum + ((r["totalCapacity"] ?? 0) as num).toInt(),
        ),
      };

      setState(() {
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

  void searchRoom(String value) {
    List temp = List.from(rooms);

    if (selectedFilter != "All") {
      temp = temp.where((room) {
        return (room["status"] ?? "").toString().toLowerCase() ==
            selectedFilter.toLowerCase();
      }).toList();
    }

    if (value.isNotEmpty) {
      temp = temp.where((room) {
        return (room["roomNo"] ?? "").toString().toLowerCase().contains(
          value.toLowerCase(),
        );
      }).toList();
    }

    setState(() {
      filteredRooms = temp;
    });
  }

  void filterRooms(String filter) {
    selectedFilter = filter;

    List temp = List.from(rooms);

    if (filter != "All") {
      temp = temp.where((room) {
        return (room["status"] ?? "").toString().toLowerCase() ==
            filter.toLowerCase();
      }).toList();
    }

    if (searchController.text.isNotEmpty) {
      temp = temp.where((room) {
        return (room["roomNo"] ?? "").toString().toLowerCase().contains(
          searchController.text.toLowerCase(),
        );
      }).toList();
    }

    setState(() {
      filteredRooms = temp;
    });
  }

  void _showAddRoomDialog() {
    roomNumberController.clear();
    roomTypeController.clear();
    sharingController.clear();
    rentController.clear();
    capacityController.clear();

    floorController.clear();
    occupiedController.clear();

    bedsController.clear();
    fansController.clear();
    cupboardController.clear();
    studyTableController.clear();

    notesController.clear();

    wifiAvailable = false;

    roomStatus = "available";

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Add Room"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: roomNumberController,
                  decoration: const InputDecoration(labelText: "Room Number"),
                ),

                TextField(
                  controller: floorController,
                  decoration: const InputDecoration(labelText: "Floor"),
                ),

                TextField(
                  controller: occupiedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Occupied Beds"),
                ),

                TextField(
                  controller: roomTypeController,
                  decoration: const InputDecoration(labelText: "Room Type"),
                ),

                TextField(
                  controller: sharingController,
                  decoration: const InputDecoration(labelText: "Sharing"),
                ),

                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Capacity"),
                ),

                TextField(
                  controller: rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Rent"),
                ),
                DropdownButtonFormField<bool>(
                  value: attachedBathroom,
                  decoration: const InputDecoration(
                    labelText: "Attached Bathroom",
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text("Yes")),
                    DropdownMenuItem(value: false, child: Text("No")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      attachedBathroom = value!;
                    });
                  },
                ),

                DropdownButtonFormField<bool>(
                  value: wifiAvailable,
                  decoration: const InputDecoration(
                    labelText: "WiFi Available",
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text("Yes")),
                    DropdownMenuItem(value: false, child: Text("No")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      wifiAvailable = value!;
                    });
                  },
                ),

                TextField(
                  controller: bedsController,
                  decoration: const InputDecoration(labelText: "No. of Beds"),
                ),

                TextField(
                  controller: fansController,
                  decoration: const InputDecoration(labelText: "No. of Fans"),
                ),

                TextField(
                  controller: cupboardController,
                  decoration: const InputDecoration(labelText: "Cupboards"),
                ),

                TextField(
                  controller: studyTableController,
                  decoration: const InputDecoration(labelText: "Study Tables"),
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: roomStatus,

                  decoration: const InputDecoration(labelText: "Status"),

                  items: const [
                    DropdownMenuItem(
                      value: "available",
                      child: Text("Available"),
                    ),

                    DropdownMenuItem(value: "Full", child: Text("Full")),

                    DropdownMenuItem(
                      value: "maintenance",
                      child: Text("Maintenance"),
                    ),
                  ],

                  onChanged: (value) {
                    roomStatus = value!;
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(onPressed: _createRoom, child: const Text("Create")),
          ],
        );
      },
    );
  }

  Future<void> _createRoom() async {
    try {
      final body = {
        "roomNo": roomNumberController.text,

        "floor": floorController.text,

        "roomType": roomTypeController.text,

        "seating": sharingController.text,

        "totalCapacity": int.tryParse(capacityController.text) ?? 0,
        "occupied": int.tryParse(occupiedController.text) ?? 0,

        "monthlyRent": double.tryParse(rentController.text) ?? 0,
        "attachedBathroom": attachedBathroom,
        "wifi": wifiAvailable,
        "amenities": {
          "bed": int.tryParse(bedsController.text) ?? 0,
          "fan": int.tryParse(fansController.text) ?? 0,
          "cupboard": int.tryParse(cupboardController.text) ?? 0,
          "studyTable": int.tryParse(studyTableController.text) ?? 0,
        },

        "status": roomStatus,
      };

      await RoomService.createRoom(body);

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Room Added Successfully")));

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
      title: "Rooms & Inventory",

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(15),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          "Total Rooms",
                          stats["totalRooms"]?.toString() ?? "0",
                          Icons.meeting_room,
                          Colors.indigo,
                        ),

                        _buildStatCard(
                          "Beds",
                          stats["totalBeds"]?.toString() ?? "0",
                          Icons.bed,
                          Colors.teal,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildStatCard(
                          "Vacant",
                          stats["vacantRooms"]?.toString() ?? "0",
                          Icons.event_available,
                          Colors.green,
                        ),

                        _buildStatCard(
                          "Occupied",
                          stats["occupiedRooms"]?.toString() ?? "0",
                          Icons.hotel,
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: searchController,

                      onChanged: searchRoom,

                      decoration: InputDecoration(
                        hintText: "Search room number...",

                        prefixIcon: const Icon(Icons.search),

                        filled: true,

                        fillColor: Colors.grey.shade100,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: Row(
                        children: [
                          _filterButton("All"),

                          _filterButton("available"),
                          _filterButton("full"),
                          _filterButton("maintenance"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Room Overview",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddRoomDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor:
                                Colors.white, // Text aur icon ka color
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Room"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      itemCount: filteredRooms.length,

                      itemBuilder: (context, index) {
                        return _roomCard(filteredRooms[index]);
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  /// ===============================
  /// 📊 STAT CARD
  /// ===============================
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
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
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(height: 18),

            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// FILTER BUTTON
  /// ===============================
  Widget _filterButton(String title) {
    bool isSelected = selectedFilter == title;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),

        onTap: () {
          filterRooms(title);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo : Colors.grey.shade200,

            borderRadius: BorderRadius.circular(25),

            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),

          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomCard(Map room) {
    String status = (room["status"] ?? "Available").toString();

    Color statusColor = Colors.green;

    if (status.toLowerCase() == "full") {
      statusColor = Colors.orange;
    } else if (status.toLowerCase() == "maintenance") {
      statusColor = Colors.red;
    }

    int occupied = room["occupied"] ?? 0;
    int total = room["totalCapacity"] ?? 1;

    double progress = total == 0 ? 0 : occupied / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo.withOpacity(.1),
                  child: const Icon(Icons.meeting_room, color: Colors.indigo),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Room ${room["roomNo"] ?? ""}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      Text(
                        room["roomType"] ?? "-",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _buildInfoRow(Icons.location_city, "Block", room["block"] ?? "-"),

            _buildInfoRow(Icons.hotel, "Room Type", room["roomType"] ?? "-"),
            _buildInfoRow(Icons.people, "Sharing", room["seating"] ?? "-"),

            _buildInfoRow(
              Icons.bed,
              "Capacity",
              "${room["totalCapacity"] ?? 0} Beds",
            ),

            _buildInfoRow(Icons.layers, "Floor", room["floor"] ?? "-"),

            _buildInfoRow(
              Icons.currency_rupee,
              "Rent",
              "₹${room["monthlyRent"] ?? 0}",
            ),

            _buildInfoRow(
              Icons.bathroom,
              "Attached Bathroom",
              room["attachedBathroom"] == true ? "Yes" : "No",
            ),

            _buildInfoRow(
              Icons.wifi,
              "WiFi",
              room["wifi"] == true ? "Yes" : "No",
            ),

            const SizedBox(height: 12),

            const Text(
              "Furniture",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Beds"),
                    Text(
                      "${room["amenities"]?["beds"] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                Column(
                  children: [
                    const Text("Fans"),
                    Text(
                      "${room["amenities"]?["fans"] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                Column(
                  children: [
                    const Text("Cupboards"),
                    Text(
                      "${room["amenities"]?["cupboards"] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                Column(
                  children: [
                    const Text("Tables"),
                    Text(
                      "${room["amenities"]?["tables"] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              "Occupancy",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$occupied / $total Beds",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

            const Divider(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    _showEditRoomDialog(room);
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),

                IconButton(
                  onPressed: () {
                    _deleteRoom(room);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),

          const SizedBox(width: 12),

          Text(title, style: TextStyle(color: Colors.grey.shade700)),

          const Spacer(),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
