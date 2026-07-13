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

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    try {
      setState(() => isLoading = announcements.isEmpty);
      final response = await AnnouncementService.getAnnouncements();

      if (mounted) {
        setState(() {
          announcements = response["data"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint('Failed to load announcements: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to remove this announcement? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AnnouncementService.deleteAnnouncement(id);
        await loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Announcement Deleted Successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Announcements",
      body: Container(
        color: const Color(0xffF6F8FC),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : PullToRefresh(
                onRefresh: loadAnnouncements,
                child: SingleChildScrollView(
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
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Recent Broadcasts",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff111827),
                                ),
                              ),
                              Text(
                                "Total: ${announcements.length}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (announcements.isEmpty)
                            const _EmptyAnnouncementsState()
                          else
                            _buildAnnouncementList(),
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
          colors: [Color(0xff1E3A8A), Color(0xff2563EB), Color(0xff60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563EB).withOpacity(.2),
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
                  "Hostel Broadcast",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Keep everyone updated with important notices, events, and maintenance schedules.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showAnnouncementDialog(),
            icon: const Icon(Icons.campaign_rounded),
            label: const Text("Post Update"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 1.8,
          children: [
            _buildKpiCard(
              "Total Posts",
              announcements.length.toString(),
              Icons.all_inbox_rounded,
              const Color(0xff6366F1),
            ),
            _buildKpiCard(
              "Urgent",
              announcements.where((e) => e["priority"] == "high" || e["priority"] == "urgent").length.toString(),
              Icons.error_outline_rounded,
              const Color(0xffEF4444),
            ),
            _buildKpiCard(
              "Events",
              announcements.where((e) => e["category"] == "event").length.toString(),
              Icons.event_available_rounded,
              const Color(0xffF59E0B),
            ),
            _buildKpiCard(
              "Active",
              announcements.where((e) => e["isActive"] == true).length.toString(),
              Icons.check_circle_outline_rounded,
              const Color(0xff10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final item = announcements[index];
        return AnnouncementListItem(
          announcement: item,
          onEdit: () => _showAnnouncementDialog(announcement: item),
          onDelete: () => deleteAnnouncement(item["_id"] ?? item["id"]),
        );
      },
    );
  }

  void _showAnnouncementDialog({Map? announcement}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnnouncementFormDialog(
        announcement: announcement,
        onSaved: loadAnnouncements,
      ),
    );
  }
}

class AnnouncementListItem extends StatelessWidget {
  final Map announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementListItem({
    super.key,
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String priority = announcement["priority"]?.toString().toLowerCase() ?? "low";
    final String category = announcement["category"]?.toString().toLowerCase() ?? "general";
    final Color priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: priorityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildCategoryBadge(category),
                          const SizedBox(width: 8),
                          if (priority == "high" || priority == "urgent")
                            _buildUrgentBadge(),
                          const Spacer(),
                          _buildActionMenu(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcement["title"] ?? "No Title",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff111827)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement["message"] ?? "No Message",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(announcement["createdAt"]),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.groups_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "For: ${announcement["targetAudience"]?.toString().toUpperCase() ?? "ALL"}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color = Colors.blue;
    IconData icon = Icons.info_outline_rounded;

    switch (category) {
      case 'urgent':
        color = Colors.red;
        icon = Icons.notification_important_rounded;
        break;
      case 'event':
        color = Colors.purple;
        icon = Icons.celebration_rounded;
        break;
      case 'maintenance':
        color = Colors.orange;
        icon = Icons.settings_suggest_rounded;
        break;
      case 'policy':
        color = Colors.indigo;
        icon = Icons.gavel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "URGENT",
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
              SizedBox(width: 10),
              Text("Edit Broadcast"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text("Remove Post", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    final text = date.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
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
}

class AnnouncementFormDialog extends StatefulWidget {
  final Map? announcement;
  final VoidCallback onSaved;

  const AnnouncementFormDialog({super.key, this.announcement, required this.onSaved});

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  String selectedCategory = "general";
  String selectedPriority = "low";
  String selectedAudience = "all";

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      titleController.text = widget.announcement!["title"] ?? "";
      messageController.text = widget.announcement!["message"] ?? "";
      selectedCategory = widget.announcement!["category"] ?? "general";
      selectedPriority = widget.announcement!["priority"] ?? "low";
      selectedAudience = widget.announcement!["targetAudience"] ?? "all";
    }
  }

  Future<void> _handleSave() async {
    if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and Message are required")));
      return;
    }

    final body = {
      "title": titleController.text.trim(),
      "message": messageController.text.trim(),
      "category": selectedCategory,
      "priority": selectedPriority,
      "targetAudience": selectedAudience,
      "expiresAt": DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };

    try {
      if (widget.announcement != null) {
        await AnnouncementService.updateAnnouncement(
          widget.announcement!["_id"] ?? widget.announcement!["id"],
          body,
        );
      } else {
        await AnnouncementService.createAnnouncement(body);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving announcement: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.announcement != null;

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
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.campaign_rounded,
                    color: const Color(0xff2563EB),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? "Edit Announcement" : "Post New Broadcast",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                  ),
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
                    _buildLabel("Update Title *"),
                    TextField(
                      controller: titleController,
                      decoration: _buildInputDecoration("e.g. Maintenance Work Notice"),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Broadcast Message *"),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: _buildInputDecoration("Enter the full details of the update..."),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Crucial fix: Increased threshold to 440 to force Column on most phones
                        if (constraints.maxWidth < 440) {
                          return Column(
                            children: [
                              _buildDropdownField(
                                "Category",
                                selectedCategory,
                                ["general", "urgent", "event", "maintenance", "policy"],
                                (val) => setState(() => selectedCategory = val!),
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                "Priority",
                                selectedPriority,
                                ["low", "medium", "high", "urgent"],
                                (val) => setState(() => selectedPriority = val!),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                "Category",
                                selectedCategory,
                                ["general", "urgent", "event", "maintenance", "policy"],
                                (val) => setState(() => selectedCategory = val!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                "Priority",
                                selectedPriority,
                                ["low", "medium", "high", "urgent"],
                                (val) => setState(() => selectedPriority = val!),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      "Target Audience",
                      selectedAudience,
                      ["all", "residents", "staff"],
                      (val) => setState(() => selectedAudience = val!),
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
                      backgroundColor: const Color(0xff2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? "Update Post" : "Broadcast Now"),
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
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14),
      ),
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
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e[0].toUpperCase() + e.substring(1), style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BoxBorderSide(color: Color(0xff2563EB), width: 1.5),
      ),
    );
  }
}

class BoxBorderSide extends BorderSide {
  const BoxBorderSide({super.color, super.width});
}

class _EmptyAnnouncementsState extends StatelessWidget {
  const _EmptyAnnouncementsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No Broadcasts Yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Start broadcasting updates to keep residents and staff informed about hostel activities.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
