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
      final response = await RoleService.getRoles();

      setState(() {
        roles = response["data"];
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> saveRole(Map<String, dynamic> body) async {
    print(body); // <-- ye add karo

    try {
      final response = await RoleService.createRole(body);

      print(response);

      if (response["success"] == true) {
        loadRoles();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Role created successfully")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      final response = await RoleService.deleteRole(id);

      if (response["success"] == true) {
        loadRoles();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Role deleted")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> updateRole(String id, Map<String, dynamic> body) async {
    try {
      final response = await RoleService.updateRole(id, body);

      if (response["success"] == true) {
        loadRoles();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Role updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> showDeleteDialog(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Role"),
        content: const Text("Are you sure you want to delete this role?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PullToRefresh(
  onRefresh: loadRoles,
  child:SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Roles & Permissions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
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
                        icon: const Icon(Icons.add),
                        label: const Text("Create Role"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(roles.length, (index) {
                      final role = roles[index];
                      return RoleCard(
                        roleName: role["name"] ?? "",
                        description: role["description"] ?? "",
                        onDelete: () {
                          showDeleteDialog(role["_id"]);
                        },
                        isSystem: role["isSystem"],
                        permissions: List<String>.from(
                          role["permissions"] ?? [],
                        ),

                        onEdit: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (_) => CreateRoleDialog(role: role),
                          );

                          if (result != null) {
                            await updateRole(role["_id"], result);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),)
    );
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

 Map<String, String> permissionLabels = {
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

Map<String, bool> permissions = {
  "manage_dashboard": false,
  "manage_roles": false,
  "manage_users": false,
  "manage_residents": false,
  "manage_rooms": false,
  "manage_fees": false,
  "manage_attendance": false,
  "manage_complaints": false,
  "manage_visitors": false,
  "manage_announcements": false,
};

  @override
  void initState() {
    super.initState();

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
    return AlertDialog(
      title: Text(
        widget.role == null ? "Create New Role" : "Edit Role",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Role Name *"),
              const SizedBox(height: 8),

              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  hintText: "e.g. Warden",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Description"),
              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Brief description of this role...",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Module Permissions",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...permissions.keys.map((permission) {
                return CheckboxListTile(
                  value: permissions[permission],
                  title: Text(permissionLabels[permission]!),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      permissions[permission] = value!;
                    });
                  },
                );
              }).toList(),
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
          onPressed: () {
            final selectedPermissions = permissions.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

            Navigator.pop(context, {
              "name": roleController.text,
              "description": descriptionController.text,
              "permissions": selectedPermissions,
              "isSystem": false,
            });
          },
          child: Text(widget.role == null ? "Save Role" : "Update Role"),
        ),
      ],
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
    final visiblePermissions = permissions.take(3).toList();

    return Container(
      width: 320,
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  roleName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),

              if (isSystem)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "SYSTEM",
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),

          const SizedBox(height: 30),

          Text(
            "ASSIGNED PERMISSIONS",
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visiblePermissions.map(
                (e) =>
                    Chip(backgroundColor: Colors.grey.shade100, label: Text(e)),
              ),

              if (permissions.length > 3)
                Chip(
                  backgroundColor: Colors.indigo.shade50,
                  label: Text(
                    "+${permissions.length - 3} more",
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.blue),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
