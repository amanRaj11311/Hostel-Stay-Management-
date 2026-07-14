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
  final TextEditingController searchController = TextEditingController();

  String selectedBlock = "A";
  bool attachedBathroom = true;
  bool wifiAvailable = true;
  String roomStatus = "available";
  String selectedFilter = "All";
  bool isLoading = true;

  List rooms = [];
  List filteredRooms = [];
  Map<String, dynamic> stats = {
    "vacantRooms": 0,
    "occupiedRooms": 0,
    "totalRooms": 0,
    "totalBeds": 0,
  };

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
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = rooms.isEmpty);

      final roomRes = await RoomService.getRooms();
      final statsRes = await RoomService.getRoomStats();

      if (mounted) {
        setState(() {
          rooms = roomRes["data"] ?? [];
          applyFilters();

          List statsList = statsRes["data"] ?? [];
          int available = 0;
          int occupied = 0;

          for (var item in statsList) {
            if (item["_id"] == "available") available = item["count"] ?? 0;
            if (item["_id"] == "occupied") occupied = item["count"] ?? 0;
          }

          stats = {
            "vacantRooms": available,
            "occupiedRooms": occupied,
            "totalRooms": available + occupied,
            "totalBeds": rooms.fold<int>(0, (sum, r) => sum + ((r["totalCapacity"] ?? 0) as num).toInt()),
          };
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error loading data: $e");
    }
  }

  void applyFilters() {
    setState(() {
      filteredRooms = rooms.where((room) {
        final query = searchController.text.toLowerCase();
        final roomNo = (room["roomNo"] ?? "").toString().toLowerCase();
        final matchSearch = roomNo.contains(query);
        final matchFilter = selectedFilter == "All" || (room["status"] ?? "").toString().toLowerCase() == selectedFilter.toLowerCase();
        return matchSearch && matchFilter;
      }).toList();
    });
  }

  void _showAddRoomDialog() {
    _resetControllers();
    showDialog(
      context: context,
      builder: (context) => RoomFormDialog(
        title: "Add New Room",
        onSave: _createRoom,
        roomNumberController: roomNumberController,
        floorController: floorController,
        occupiedController: occupiedController,
        roomTypeController: roomTypeController,
        sharingController: sharingController,
        capacityController: capacityController,
        rentController: rentController,
        bedsController: bedsController,
        fansController: fansController,
        cupboardController: cupboardController,
        studyTableController: studyTableController,
        selectedBlock: selectedBlock,
        attachedBathroom: attachedBathroom,
        wifiAvailable: wifiAvailable,
        roomStatus: roomStatus,
        onBlockChanged: (val) => selectedBlock = val!,
        onBathroomChanged: (val) => attachedBathroom = val!,
        onWifiChanged: (val) => wifiAvailable = val!,
        onStatusChanged: (val) => roomStatus = val!,
      ),
    );
  }

  void _showEditRoomDialog(Map room) {
    roomNumberController.text = room["roomNo"]?.toString() ?? "";
    roomTypeController.text = room["roomType"]?.toString() ?? "";
    sharingController.text = room["seating"]?.toString() ?? "";
    capacityController.text = room["totalCapacity"]?.toString() ?? "";
    rentController.text = room["monthlyRent"]?.toString() ?? "";
    floorController.text = room["floor"]?.toString() ?? "";
    occupiedController.text = room["occupied"]?.toString() ?? "0";
    bedsController.text = room["amenities"]?["beds"]?.toString() ?? "0";
    fansController.text = room["amenities"]?["fans"]?.toString() ?? "0";
    cupboardController.text = room["amenities"]?["cupboards"]?.toString() ?? "0";
    studyTableController.text = room["amenities"]?["tables"]?.toString() ?? "0";
    selectedBlock = room["block"] ?? "A";
    attachedBathroom = room["attachedBathroom"] == true;
    wifiAvailable = room["wifi"] == true;
    roomStatus = room["status"] ?? "available";

    showDialog(
      context: context,
      builder: (context) => RoomFormDialog(
        title: "Edit Room",
        onSave: () => _updateRoom(room["_id"].toString()),
        roomNumberController: roomNumberController,
        floorController: floorController,
        occupiedController: occupiedController,
        roomTypeController: roomTypeController,
        sharingController: sharingController,
        capacityController: capacityController,
        rentController: rentController,
        bedsController: bedsController,
        fansController: fansController,
        cupboardController: cupboardController,
        studyTableController: studyTableController,
        selectedBlock: selectedBlock,
        attachedBathroom: attachedBathroom,
        wifiAvailable: wifiAvailable,
        roomStatus: roomStatus,
        onBlockChanged: (val) => selectedBlock = val!,
        onBathroomChanged: (val) => attachedBathroom = val!,
        onWifiChanged: (val) => wifiAvailable = val!,
        onStatusChanged: (val) => roomStatus = val!,
      ),
    );
  }

  void _resetControllers() {
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
    selectedBlock = "A";
    attachedBathroom = true;
    wifiAvailable = true;
    roomStatus = "available";
  }

  Future<void> _createRoom() async {
    try {
      final body = _getRoomBody();
      await RoomService.createRoom(body);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room added successfully"), behavior: SnackBarBehavior.floating));
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _updateRoom(String id) async {
    try {
      final body = _getRoomBody();
      await RoomService.updateRoom(id, body);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room updated successfully"), behavior: SnackBarBehavior.floating));
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    }
  }

  Map<String, dynamic> _getRoomBody() {
    return {
      "roomNo": roomNumberController.text,
      "floor": floorController.text,
      "roomType": roomTypeController.text,
      "seating": sharingController.text,
      "totalCapacity": int.tryParse(capacityController.text) ?? 0,
      "occupied": int.tryParse(occupiedController.text) ?? 0,
      "monthlyRent": double.tryParse(rentController.text) ?? 0,
      "attachedBathroom": attachedBathroom,
      "wifi": wifiAvailable,
      "block": selectedBlock,
      "amenities": {
        "beds": int.tryParse(bedsController.text) ?? 0,
        "fans": int.tryParse(fansController.text) ?? 0,
        "cupboards": int.tryParse(cupboardController.text) ?? 0,
        "tables": int.tryParse(studyTableController.text) ?? 0,
      },
      "status": roomStatus,
    };
  }

  Future<void> _deleteRoom(Map room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Room"),
        content: Text("Are you sure you want to delete Room ${room["roomNo"]}? This will remove all associated history."),
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
        await RoomService.deleteRoom(room["_id"].toString());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room deleted"), behavior: SnackBarBehavior.floating));
        loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Rooms & Inventory",
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
                          if (filteredRooms.isEmpty)
                            const _EmptyRoomsState()
                          else
                            _buildRoomsGrid(),
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
          colors: [Color(0xff0891B2), Color(0xff06B6D4), Color(0xff22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff06B6D4).withOpacity(.2),
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
                  "Inventory Control",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Manage room status, floor planning and hostel equipment tracking.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddRoomDialog,
            icon: const Icon(Icons.add_home_work_rounded),
            label: const Text("Add Room"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff0891B2),
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
          _buildKpiCard("Total Units", "${stats["totalRooms"]}", Icons.door_front_door_rounded, Colors.indigo),
          _buildKpiCard("Bed Capacity", "${stats["totalBeds"]}", Icons.bed_rounded, Colors.teal),
          _buildKpiCard("Vacant Units", "${stats["vacantRooms"]}", Icons.event_available_rounded, Colors.green),
          _buildKpiCard("Full / Maint.", "${stats["occupiedRooms"]}", Icons.hotel_rounded, Colors.red),
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
      onChanged: (v) => applyFilters(),
      decoration: InputDecoration(
        hintText: "Search room number...",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xff0891B2)),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedFilter,
        isExpanded: true,
        icon: const Icon(Icons.filter_list_rounded, color: Colors.grey),
        items: const [
          DropdownMenuItem(value: "All", child: Text("All Status")),
          DropdownMenuItem(value: "available", child: Text("Available")),
          DropdownMenuItem(value: "full", child: Text("Full")),
          DropdownMenuItem(value: "maintenance", child: Text("Maintenance")),
        ],
        onChanged: (value) {
          setState(() {
            selectedFilter = value!;
            applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildRoomsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 380;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 3);
      
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: filteredRooms.map((item) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
            child: RoomCard(
              room: item,
              onEdit: () => _showEditRoomDialog(item),
              onDelete: () => _deleteRoom(item),
            ),
          );
        }).toList(),
      );
    });
  }
}

class RoomCard extends StatelessWidget {
  final Map room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoomCard({
    super.key,
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = (room["status"] ?? "available").toString().toLowerCase();
    Color statusColor = Colors.green;
    if (status == "full") statusColor = Colors.orange;
    if (status == "maintenance") statusColor = Colors.red;

    final int occupied = room["occupied"] ?? 0;
    final int total = room["totalCapacity"] ?? 1;
    final double progress = total == 0 ? 0 : occupied / total;

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
              _buildAvatar(room["roomNo"]?.toString() ?? "?"),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Room ${room["roomNo"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("${room["roomType"] ?? "-"} • Block ${room["block"] ?? "-"}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              _StatusBadge(status: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmenityIcon(icon: Icons.people_outline_rounded, label: room["seating"] ?? "-"),
              _AmenityIcon(icon: Icons.layers_outlined, label: "Floor ${room["floor"] ?? "-"}"),
              _AmenityIcon(icon: Icons.currency_rupee_rounded, label: "₹${room["monthlyRent"] ?? 0}"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (room["wifi"] == true) _FeatureChip(icon: Icons.wifi, label: "WiFi"),
              if (room["attachedBathroom"] == true) ...[
                if (room["wifi"] == true) const SizedBox(width: 8),
                _FeatureChip(icon: Icons.bathroom_outlined, label: "Attached"),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Text("Furniture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff374151))),
          const SizedBox(height: 12),
          _FurnitureGrid(amenities: room["amenities"]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Occupancy", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$occupied / $total Beds", style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, color: Colors.blue)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String roomNo) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xff0891B2).withOpacity(0.8), const Color(0xff06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 24),
    );
  }
}

class _FurnitureGrid extends StatelessWidget {
  final Map? amenities;
  const _FurnitureGrid({this.amenities});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FurnitureItem(icon: Icons.bed_outlined, count: amenities?["beds"] ?? 0, label: "Beds"),
        _FurnitureItem(icon: Icons.air_rounded, count: amenities?["fans"] ?? 0, label: "Fans"),
        _FurnitureItem(icon: Icons.inventory_2_outlined, count: amenities?["cupboards"] ?? 0, label: "Cupboards"),
        _FurnitureItem(icon: Icons.desk_outlined, count: amenities?["tables"] ?? 0, label: "Tables"),
      ],
    );
  }
}

class _FurnitureItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  const _FurnitureItem({required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
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
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _AmenityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class RoomFormDialog extends StatefulWidget {
  final String title;
  final VoidCallback onSave;
  final TextEditingController roomNumberController;
  final TextEditingController floorController;
  final TextEditingController occupiedController;
  final TextEditingController roomTypeController;
  final TextEditingController sharingController;
  final TextEditingController capacityController;
  final TextEditingController rentController;
  final TextEditingController bedsController;
  final TextEditingController fansController;
  final TextEditingController cupboardController;
  final TextEditingController studyTableController;
  final String selectedBlock;
  final bool attachedBathroom;
  final bool wifiAvailable;
  final String roomStatus;
  final ValueChanged<String?> onBlockChanged;
  final ValueChanged<bool?> onBathroomChanged;
  final ValueChanged<bool?> onWifiChanged;
  final ValueChanged<String?> onStatusChanged;

  const RoomFormDialog({
    super.key,
    required this.title,
    required this.onSave,
    required this.roomNumberController,
    required this.floorController,
    required this.occupiedController,
    required this.roomTypeController,
    required this.sharingController,
    required this.capacityController,
    required this.rentController,
    required this.bedsController,
    required this.fansController,
    required this.cupboardController,
    required this.studyTableController,
    required this.selectedBlock,
    required this.attachedBathroom,
    required this.wifiAvailable,
    required this.roomStatus,
    required this.onBlockChanged,
    required this.onBathroomChanged,
    required this.onWifiChanged,
    required this.onStatusChanged,
  });

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  late String _currentBlock;
  late bool _currentBathroom;
  late bool _currentWifi;
  late String _currentStatus;
  late String _currentRoomType;
  late String _currentSharing;

  @override
  void initState() {
    super.initState();
    _currentBlock = (["A", "B", "C", "D"].contains(widget.selectedBlock)) ? widget.selectedBlock : "A";
    _currentBathroom = widget.attachedBathroom;
    _currentWifi = widget.wifiAvailable;
    _currentStatus = (["available", "full", "maintenance"].contains(widget.roomStatus)) ? widget.roomStatus : "available";

    // Initialize dropdown values from controllers with validation
    String roomTypeValue = widget.roomTypeController.text.isEmpty ? "AC" : widget.roomTypeController.text;
    _currentRoomType = (["AC", "Non AC"].contains(roomTypeValue)) ? roomTypeValue : "AC";
    
    String sharingValue = widget.sharingController.text.isEmpty ? "2 Sharing" : widget.sharingController.text;
    _currentSharing = (["1 Sharing", "2 Sharing", "3 Sharing", "4 Sharing"].contains(sharingValue)) ? sharingValue : "2 Sharing";

    // Ensure controllers have valid values
    widget.roomTypeController.text = _currentRoomType;
    widget.sharingController.text = _currentSharing;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.add_home_work_rounded, color: Color(0xff0891B2), size: 28),
                  const SizedBox(width: 12),
                  Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    _buildSectionTitle("Basic Info"),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Room No *", widget.roomNumberController, "e.g. 101")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Floor", widget.floorController, "e.g. 1st")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField<String>(
                            "Room Type",
                            _currentRoomType,
                            ["AC", "Non AC"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            (v) {
                              setState(() {
                                _currentRoomType = v!;
                                widget.roomTypeController.text = v;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField<String>(
                            "Sharing",
                            _currentSharing,
                            ["1 Sharing", "2 Sharing", "3 Sharing", "4 Sharing"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            (v) {
                              setState(() {
                                _currentSharing = v!;
                                widget.sharingController.text = v;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Capacity", widget.capacityController, "Total Beds", keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Occupied", widget.occupiedController, "Current", keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Rent", widget.rentController, "Monthly ₹", keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField<String>(
                            "Block",
                            _currentBlock,
                            ["A", "B", "C", "D"].map((e) => DropdownMenuItem(value: e, child: Text("Block $e"))).toList(),
                            (v) {
                              setState(() => _currentBlock = v!);
                              widget.onBlockChanged(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Facilities"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField<bool>(
                            "Bathroom",
                            _currentBathroom,
                            [const DropdownMenuItem(value: true, child: Text("Attached")), const DropdownMenuItem(value: false, child: Text("Common"))],
                            (v) {
                              setState(() => _currentBathroom = v!);
                              widget.onBathroomChanged(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField<bool>(
                            "WiFi",
                            _currentWifi,
                            [const DropdownMenuItem(value: true, child: Text("Available")), const DropdownMenuItem(value: false, child: Text("No WiFi"))],
                            (v) {
                              setState(() => _currentWifi = v!);
                              widget.onWifiChanged(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Amenities Count"),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Beds", widget.bedsController, "0", keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField("Fans", widget.fansController, "0", keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField("Cupboards", widget.cupboardController, "0", keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField("Tables", widget.studyTableController, "0", keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDropdownField<String>(
                      "Room Status",
                      _currentStatus,
                      ["available", "full", "maintenance"].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                      (v) {
                        setState(() => _currentStatus = v!);
                        widget.onStatusChanged(v);
                      },
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
                    onPressed: widget.onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0891B2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save Details"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff0891B2), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class BoxBorderSide extends BorderSide {
  const BoxBorderSide({super.color, super.width});
}

class _EmptyRoomsState extends StatelessWidget {
  const _EmptyRoomsState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.meeting_room_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No Rooms Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Try changing your filters or add a new room to get started.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
