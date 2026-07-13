import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';
import '../api/role_service.dart';
import 'responsive.dart';
import 'pull_to_refresh.dart';

class RolesAndPermissionsScreens extends StatefulWidget {
  const RolesAndPermissionsScreens({super.key});

  @override
  State<RolesAndPermissionsScreens> createState() =>
      _RolesAndPermissionsScreensState();
}

class _RolesAndPermissionsScreensState
    extends State<RolesAndPermissionsScreens> {
  List roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    try {
      setState(() => isLoading = roles.isEmpty);
      final response = await RoleService.getRoles();

      if (mounted) {
        setState(() {
          roles = response["data"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint(e.toString());
    }
  }

  Future<void> saveRole(Map<String, dynamic> body) async {
    try {
      final response = await RoleService.createRole(body);
      if (response["success"] == true) {
        loadRoles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role created successfully")),
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      final response = await RoleService.deleteRole(id);
      if (response["success"] == true) {
        loadRoles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role deleted")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> updateRole(String id, Map<String, dynamic> body) async {
    try {
      final response = await RoleService.updateRole(id, body);
      if (response["success"] == true) {
        loadRoles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Role updated successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> showDeleteDialog(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Role"),
        content: const Text("Are you sure you want to delete this role? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteRole(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Roles & Permissions",
      body: Container(
        color: const Color(0xffF6F8FC),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : PullToRefresh(
                onRefresh: loadRoles,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 30),
                          if (roles.isEmpty)
                            const _EmptyRolesState()
                          else
                            _buildRolesGrid(),
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
          colors: [Color(0xff1E40AF), Color(0xff2563EB), Color(0xff38BDF8)],
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
                  "Access Control",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Define and manage roles, permissions and system access levels.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => const CreateRoleDialog(),
              );
              if (result != null) {
                await saveRole(result);
              }
            },
            icon: const Icon(Icons.add_moderator_rounded),
            label: const Text("Create New Role"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 350;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 4);
      
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: roles.map((role) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : cardWidth,
            child: RoleCard(
              roleName: role["name"] ?? "",
              description: role["description"] ?? "",
              onDelete: () => showDeleteDialog(role["_id"]),
              isSystem: role["isSystem"] ?? false,
              permissions: List<String>.from(role["permissions"] ?? []),
              onEdit: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => CreateRoleDialog(role: role),
                );
                if (result != null) {
                  await updateRole(role["_id"], result);
                }
              },
            ),
          );
        }).toList(),
      );
    });
  }
}

class CreateRoleDialog extends StatefulWidget {
  final Map<String, dynamic>? role;
  const CreateRoleDialog({super.key, this.role});

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final Map<String, String> permissionLabels = {
    "manage_dashboard": "Dashboard Access",
    "manage_roles": "Manage Roles & Permissions",
    "manage_users": "Manage Users",
    "manage_residents": "Manage Residents",
    "manage_rooms": "Manage Rooms & Inventory",
    "manage_fees": "Manage Fee Collection",
    "manage_attendance": "Manage Attendance",
    "manage_complaints": "Manage Complaints",
    "manage_visitors": "Manage Visitors",
    "manage_announcements": "Manage Announcements",
  };

  Map<String, bool> permissions = {};

  @override
  void initState() {
    super.initState();
    // Initialize all permissions to false
    for (var key in permissionLabels.keys) {
      permissions[key] = false;
    }

    if (widget.role != null) {
      roleController.text = widget.role!["name"] ?? "";
      descriptionController.text = widget.role!["description"] ?? "";
      List permissionList = widget.role!["permissions"] ?? [];
      for (var key in permissions.keys) {
        permissions[key] = permissionList.contains(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Icon(
                    widget.role == null ? Icons.add_moderator_rounded : Icons.edit_note_rounded,
                    color: const Color(0xff2563EB),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.role == null ? "Create New Role" : "Edit Role Details",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
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
                    _buildLabel("Role Name *"),
                    TextField(
                      controller: roleController,
                      decoration: _buildInputDecoration("e.g. Warden, Admin"),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("Description"),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: _buildInputDecoration("Briefly explain the responsibilities of this role..."),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Module Permissions",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: permissions.keys.map((key) {
                          return CheckboxListTile(
                            value: permissions[key],
                            title: Text(permissionLabels[key]!, style: const TextStyle(fontSize: 14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: const Color(0xff2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onChanged: (value) => setState(() => permissions[key] = value!),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (roleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Role name is required")),
                        );
                        return;
                      }
                      final selectedPermissions = permissions.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();

                      Navigator.pop(context, {
                        "name": roleController.text.trim(),
                        "description": descriptionController.text.trim(),
                        "permissions": selectedPermissions,
                        "isSystem": widget.role?["isSystem"] ?? false,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.role == null ? "Create Role" : "Update Role"),
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
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.5),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String roleName;
  final String description;
  final bool isSystem;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final List<String> permissions;

  const RoleCard({
    super.key,
    required this.roleName,
    required this.description,
    required this.isSystem,
    required this.permissions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> permissionLabels = {
      "manage_dashboard": "Dashboard",
      "manage_roles": "Roles",
      "manage_users": "Users",
      "manage_residents": "Residents",
      "manage_rooms": "Rooms",
      "manage_fees": "Fees",
      "manage_attendance": "Attendance",
      "manage_complaints": "Complaints",
      "manage_visitors": "Visitors",
      "manage_announcements": "Announce",
    };

    final displayPermissions = permissions.map((p) => permissionLabels[p] ?? p).toList();
    final visiblePermissions = displayPermissions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSystem ? Colors.amber : const Color(0xff2563EB)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSystem ? Icons.admin_panel_settings_rounded : Icons.person_pin_rounded,
                  color: isSystem ? Colors.amber.shade800 : const Color(0xff2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSystem)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "SYSTEM DEFINED",
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildActionMenu(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description.isEmpty ? "No description provided for this role." : description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          const Text(
            "PERMISSIONS",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...visiblePermissions.map((e) => _buildPermissionChip(e)),
              if (displayPermissions.length > 5)
                _buildPermissionChip("+${displayPermissions.length - 5} more", isMore: true),
              if (displayPermissions.isEmpty)
                Text("No permissions assigned", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
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
              Text("Edit Role"),
            ],
          ),
        ),
        if (!isSystem)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                SizedBox(width: 10),
                Text("Delete Role", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildPermissionChip(String label, {bool isMore = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMore ? const Color(0xffEEF2FF) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isMore ? const Color(0xff4F46E5) : Colors.grey.shade700,
          fontSize: 11,
          fontWeight: isMore ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyRolesState extends StatelessWidget {
  const _EmptyRolesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              "No Roles Configured",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Start by creating roles and assigning module permissions to manage system access.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
