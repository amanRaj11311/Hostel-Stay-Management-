import 'package:flutter/material.dart';
import '../api/user_service.dart';
import '../widgets/mainlayout.dart';
import '../api/role_service.dart';
import 'responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pull_to_refresh.dart';

class UsermanAgementScreen extends StatefulWidget {
  const UsermanAgementScreen({super.key});

  @override
  State<UsermanAgementScreen> createState() => _UsermanAgementScreenState();
}

class _UsermanAgementScreenState extends State<UsermanAgementScreen> {
  final TextEditingController searchController = TextEditingController();

  List users = [];
  List filteredUsers = [];
  List roles = [];
  bool isLoading = true;
  List<String> permissions = [];

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadPermissions();
    await loadRoles();
    await loadData();
  }

  Future<void> loadPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        permissions = prefs.getStringList("permissions") ?? [];
      });
    }
  }

  Future<void> loadRoles() async {
    try {
      final response = await RoleService.getRoles();
      if (mounted) {
        setState(() {
          roles = response["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading roles: $e");
    }
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = users.isEmpty);
      final response = await UserService.getUsers();
      if (mounted) {
        setState(() {
          users = response["data"] ?? [];
          filteredUsers = users;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error loading users: $e");
    }
  }

  void searchUser(String value) {
    setState(() {
      filteredUsers = users.where((item) {
        final name = item["name"]?.toString().toLowerCase() ?? "";
        final email = item["email"]?.toString().toLowerCase() ?? "";
        final roleName = item["role"]?["name"]?.toString().toLowerCase() ?? "";
        final query = value.toLowerCase();
        return name.contains(query) || email.contains(query) || roleName.contains(query);
      }).toList();
    });
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await UserService.deleteUser(id);
      if (response["success"] == true) {
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void showDeleteDialog(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to remove this user? This will revoke their access immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
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
      await deleteUser(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission("manage_users")) {
      return const Scaffold(
        body: Center(child: Text("You don't have permission to access this page")),
      );
    }

    return MainLayout(
      title: "User Management",
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
                          _buildSearchSection(),
                          const SizedBox(height: 24),
                          if (filteredUsers.isEmpty)
                            const _EmptyUsersState()
                          else
                            _buildUserGrid(),
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
          colors: [Color(0xff4338CA), Color(0xff6366F1), Color(0xff818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6366F1).withOpacity(.2),
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
                  "Staff & Admins",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Manage administrative accounts, wardens, and staff access levels.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showUserFormDialog(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text("Create User"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff4338CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: searchUser,
        decoration: InputDecoration(
          hintText: "Search by name, email or role...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xff6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildUserGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = 350;
      final int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(1, 4);

      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: filteredUsers.map((user) {
          return SizedBox(
            width: crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
            child: UserCard(
              user: user,
              hasPermission: hasPermission("manage_users"),
              onEdit: () => _showUserFormDialog(user: user),
              onDelete: () => showDeleteDialog(user["_id"]),
              onResetPassword: () => _showResetPasswordDialog(user["_id"]),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showUserFormDialog({Map? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        roles: roles,
        onSaved: loadData,
      ),
    );
  }

  void _showResetPasswordDialog(String id) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter a new password for this user."),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
                return;
              }
              final response = await UserService.resetPassword(id, {"newPassword": passController.text.trim()});
              if (response["success"] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully")));
              }
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map user;
  final bool hasPermission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  const UserCard({
    super.key,
    required this.user,
    required this.hasPermission,
    required this.onEdit,
    required this.onDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final String name = user["name"] ?? "Unknown";
    final String email = user["email"] ?? "No Email";
    final String roleName = user["role"]?["name"] ?? "No Role";
    final bool isSystem = user["isSystem"] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasPermission) _buildActionMenu(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xffEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: Color(0xff4F46E5)),
                    const SizedBox(width: 6),
                    Text(
                      roleName.toUpperCase(),
                      style: const TextStyle(color: Color(0xff4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isSystem)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    "SYSTEM",
                    style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xff6366F1).withOpacity(0.8), const Color(0xff4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
        if (val == 'password') onResetPassword();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
              SizedBox(width: 10),
              Text("Edit User"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'password',
          child: Row(
            children: [
              Icon(Icons.lock_reset_rounded, size: 20, color: Colors.orange),
              SizedBox(width: 10),
              Text("Reset Password"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text("Remove User", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final Map? user;
  final List roles;
  final VoidCallback onSaved;

  const UserFormDialog({super.key, this.user, required this.roles, required this.onSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedRoleId;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      nameController.text = widget.user!["name"] ?? "";
      emailController.text = widget.user!["email"] ?? "";
      selectedRoleId = widget.user!["role"]?["_id"];
    }
  }

  Future<void> _handleSave() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    final body = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "role": selectedRoleId,
    };

    try {
      if (widget.user == null) {
        body["password"] = passwordController.text.trim();
        if (body["password"]!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password is required for new users")));
          return;
        }
        await UserService.createUser(body);
      } else {
        await UserService.updateUser(widget.user!["_id"], body);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(widget.user == null ? Icons.person_add_rounded : Icons.manage_accounts_rounded, color: const Color(0xff6366F1), size: 28),
                  const SizedBox(width: 12),
                  Text(widget.user == null ? "Create New User" : "Edit User Profile", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildField("Full Name", nameController, "e.g. John Doe"),
              const SizedBox(height: 16),
              _buildField("Email Address", emailController, "e.g. john@example.com"),
              if (widget.user == null) ...[
                const SizedBox(height: 16),
                _buildField("Password", passwordController, "Min 6 characters", obscure: true),
              ],
              const SizedBox(height: 16),
              const Text("Assign Role", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRoleId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: widget.roles.map<DropdownMenuItem<String>>((role) {
                  return DropdownMenuItem<String>(value: role["_id"], child: Text(role["name"] ?? ""));
                }).toList(),
                onChanged: (val) => setState(() => selectedRoleId = val),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.user == null ? "Save User" : "Update Profile"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff6366F1), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  const _EmptyUsersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text("No Users Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "We couldn't find any users matching your search or no users are registered yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
