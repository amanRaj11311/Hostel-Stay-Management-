import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/announcement_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List announcements = [];
  bool isLoading = true;

  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String selectedCategory = "general";
  String selectedPriority = "low";
  String selectedAudience = "all";
  
  // For edit functionality
  String? editingId;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadAnnouncements() async {
    try {
      final response = await AnnouncementService.getAnnouncements();

      setState(() {
        announcements = response["data"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load announcements: $e')),
      );
    }
  }

  Future<void> saveAnnouncement() async {
    if (titleController.text.trim().isEmpty || 
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final body = {
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),
      "category": selectedCategory,
      "priority": selectedPriority,
      "targetAudience": selectedAudience,
      "expiresAt": DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
    };

    try {
      if (isEditing && editingId != null) {
        // Update existing announcement
        await AnnouncementService.updateAnnouncement(editingId!, body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement Updated Successfully")),
        );
      } else {
        // Create new announcement
        await AnnouncementService.createAnnouncement(body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement Posted Successfully")),
        );
      }

      Navigator.pop(context);
      resetForm();
      await loadAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to delete this announcement?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AnnouncementService.deleteAnnouncement(id);
        await loadAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement Deleted Successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void editAnnouncement(Map item) {
    setState(() {
      isEditing = true;
      editingId = item["_id"] ?? item["id"];
      titleController.text = item["title"] ?? "";
      messageController.text = item["message"] ?? "";
      selectedCategory = item["category"] ?? "general";
      selectedPriority = item["priority"] ?? "low";
      selectedAudience = item["targetAudience"] ?? "all";
    });
    showAnnouncementDialog();
  }

  void resetForm() {
    setState(() {
      isEditing = false;
      editingId = null;
      titleController.clear();
      messageController.clear();
      selectedCategory = "general";
      selectedPriority = "low";
      selectedAudience = "all";
    });
  }

  void showAnnouncementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(isEditing ? "Edit Announcement" : "New Announcement"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Message",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "general",
                                  child: Text("General"),
                                ),
                                DropdownMenuItem(
                                  value: "urgent",
                                  child: Text("Urgent"),
                                ),
                                DropdownMenuItem(
                                  value: "event",
                                  child: Text("Event"),
                                ),
                                DropdownMenuItem(
                                  value: "maintenance",
                                  child: Text("Maintenance"),
                                ),
                                DropdownMenuItem(
                                  value: "policy",
                                  child: Text("Policy"),
                                ),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value!;
                                });
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: "Priority",
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "low",
                                  child: Text("Low"),
                                ),
                                DropdownMenuItem(
                                  value: "medium",
                                  child: Text("Medium"),
                                ),
                                DropdownMenuItem(
                                  value: "urgent",
                                  child: Text("Urgent"),
                                ),
                                DropdownMenuItem(
                                  value: "high",
                                  child: Text("High"),
                                ),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedPriority = value!;
                                });
                                setState(() {
                                  selectedPriority = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedAudience,
                        decoration: const InputDecoration(
                          labelText: "Audience",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "all", child: Text("All")),
                          DropdownMenuItem(
                            value: "residents",
                            child: Text("Residents"),
                          ),
                          DropdownMenuItem(
                            value: "staff",
                            child: Text("Staff"),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAudience = value!;
                          });
                          setState(() {
                            selectedAudience = value!;
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
                    resetForm();
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  onPressed: saveAnnouncement,
                  icon: Icon(isEditing ? Icons.update : Icons.send, size: 18),
                  label: Text(isEditing ? "Update" : "Post"),
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
      title: "Announcements",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
              onRefresh: loadAnnouncements,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// Top Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int count = constraints.maxWidth > 900 ? 4 : 2;

                        return GridView.count(
                          crossAxisCount: count,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1,
                          children: [
                            dashboardCard(
                              "TOTAL",
                              announcements.length.toString(),
                              Icons.campaign,
                              Colors.indigo,
                            ),
                            dashboardCard(
                              "URGENT",
                              announcements
                                  .where((e) => e["priority"] == "high")
                                  .length
                                  .toString(),
                              Icons.priority_high,
                              Colors.red,
                            ),
                            dashboardCard(
                              "ACTIVE",
                              announcements
                                  .where((e) => e["isActive"] == true)
                                  .length
                                  .toString(),
                              Icons.calendar_today,
                              Colors.orange,
                            ),
                            dashboardCard(
                              "GENERAL",
                              announcements
                                  .where((e) => e["category"] == "general")
                                  .length
                                  .toString(),
                              Icons.people,
                              Colors.green,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          resetForm();
                          showAnnouncementDialog();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New Announcement"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (announcements.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            "No announcements available",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final item = announcements[index];
                          return announcementCard(
                            item,
                            onEdit: () => editAnnouncement(item),
                            onDelete: () => deleteAnnouncement(
                              item["_id"] ?? item["id"],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

Widget announcementCard(
  Map item, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 15),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: const Icon(Icons.campaign),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item["message"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(item["category"] ?? ""),
                backgroundColor: _getCategoryColor(item["category"]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                item["createdAt"]?.toString().substring(0, 10) ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item["priority"]).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Priority: ${item["priority"]}",
                  style: TextStyle(
                    color: _getPriorityColor(item["priority"]),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: "Edit",
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "Delete",
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Color _getPriorityColor(String? priority) {
  switch (priority?.toLowerCase()) {
    case 'high':
    case 'urgent':
      return Colors.red;
    case 'medium':
      return Colors.orange;
    case 'low':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Color _getCategoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'urgent':
      return Colors.red.shade100;
    case 'event':
      return Colors.purple.shade100;
    case 'maintenance':
      return Colors.orange.shade100;
    case 'policy':
      return Colors.blue.shade100;
    case 'general':
    default:
      return Colors.grey.shade200;
  }
}

Widget dashboardCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
      ],
    ),
  );
}