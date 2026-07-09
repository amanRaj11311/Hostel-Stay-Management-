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
  String editUserId = "";

  final TextEditingController editNameController = TextEditingController();

  final TextEditingController editEmailController = TextEditingController();

  String editRole = "admin";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;

  List users = [];
  List filteredUsers = [];
  List roles = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  List<String> permissions = [];

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  @override
  void initState() {
    super.initState();
    loadData();
    loadRoles();
    loadPermissions();
  }

  Future<void> loadPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      permissions = prefs.getStringList("permissions") ?? [];
    });
  }

  Future<void> loadRoles() async {
    try {
      final response = await RoleService.getRoles();

      setState(() {
        roles = response["data"] ?? [];
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateUser() async {
    final body = {
      "name": editNameController.text,
      "email": editEmailController.text,
      "role": selectedRole,
    };

    final response = await UserService.updateUser(editUserId, body);

    if (response["success"] == true) {
      Navigator.pop(context);

      loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User updated successfully")),
      );
    }
  }

  void showEditDialog(Map item) {
    editUserId = item["_id"];

    editNameController.text = item["name"];

    editEmailController.text = item["email"];

    selectedRole = item["role"]["_id"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit User"),

              content: SizedBox(
                width: 400,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editNameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: editEmailController,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Role",
                        border: OutlineInputBorder(),
                      ),
                      items: roles.map<DropdownMenuItem<String>>((role) {
                        return DropdownMenuItem<String>(
                          value:
                              role["_id"], // ya role["roleName"], backend ke hisaab se
                          child: Text(role["name"] ?? ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value!;
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
                  onPressed: updateUser,
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveUser() async {
    final body = {
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "role": selectedRole,
    };

    final response = await UserService.createUser(body);

    if (response["success"] == true) {
      Navigator.pop(context);

      nameController.clear();
      emailController.clear();
      passwordController.clear();

      loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User created successfully")),
      );
    }
  }

  void showUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create User"),

              content: SizedBox(
                width: 400,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: "Role",
                          border: OutlineInputBorder(),
                        ),
                        items: roles.map<DropdownMenuItem<String>>((role) {
                          return DropdownMenuItem<String>(
                            value: role["_id"].toString(),
                            child: Text(role["name"] ?? ""),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRole = value;
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
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(onPressed: saveUser, child: const Text("Save")),
              ],
            );
          },
        );
      },
    );
  }

  void showDeleteDialog(String id) {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Delete User"),

          content: const Text("Are you sure you want to delete this user?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                deleteUser(id);
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void showResetPasswordDialog(String id) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Reset Password"),

          content: TextField(
            controller: passwordController,

            obscureText: true,

            decoration: const InputDecoration(labelText: "New Password"),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final response = await UserService.resetPassword(id, {
                  "newPassword": passwordController.text,
                });

                if (response["success"] == true) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password Reset Successfully"),
                    ),
                  );
                }
              },

              child: const Text("Reset"),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadData() async {
    final response = await UserService.getUsers();

    setState(() {
      users = response["data"] ?? [];
      filteredUsers = users;
      isLoading = false;
    });
    print(response);
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "";
    return text[0].toUpperCase() + text.substring(1);
  }

  void searchUser(String value) {
    setState(() {
      filteredUsers = users.where((item) {
        return item["name"].toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            item["email"].toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            item["role"]["name"].toString().toLowerCase().contains(
              value.toLowerCase(),
            );
      }).toList();
    });
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await UserService.deleteUser(id);

      if (response["success"] == true) {
        loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> resetPassword(String id) async {
    try {
      final response = await UserService.resetPassword(id, {
        "newPassword": "123456",
      });

      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission("manage_users")) {
      return const Scaffold(
        body: Center(
          child: Text("You don't have permission to access this page"),
        ),
      );
    }

    return MainLayout(
      title: "User Management",
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          :  PullToRefresh(
  onRefresh: loadData,
  child:  SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  buildTopBar(),

                  const SizedBox(height: 20),

                  buildSearchSection(),

                  const SizedBox(height: 20),

                  buildUserList(),
                ],
              ),
            ),)
    );
  }

  Widget buildTopBar() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "User Management",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Manage admin access, wardens, and staffs.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: hasPermission("manage_users") ? showUserDialog : null,
          icon: const Icon(Icons.add),
          label: const Text("Create User"),
        ),
      ],
    );
  }

  Widget buildSearchSection() {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: searchController,
        onChanged: searchUser,
        decoration: InputDecoration(
          hintText: "Search user...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
  //==================== USER LIST ====================

  Widget buildUserList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final item = filteredUsers[index];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      ((item["name"]?.toString().isNotEmpty ?? false)
                          ? item["name"].toString()[0].toUpperCase()
                          : "U"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"] ?? "-",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          item["email"] ?? "-",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Role
              Row(
                children: [
                  const Icon(Icons.shield, size: 18, color: Colors.indigo),

                  const SizedBox(width: 6),

                  Text(
                    capitalize(item["role"]?["name"]?.toString() ?? "No Role"),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(width: 10),

                  if (item["isSystem"] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SYSTEM",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              /// Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasPermission("manage_users"))
                  IconButton(
                    icon: const Icon(Icons.key, color: Colors.orange),
                    onPressed: () {
                      showResetPasswordDialog(item["_id"]);
                    },
                  ),

                  if (hasPermission("manage_users"))

                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      showEditDialog(item);
                    },
                  ),

                  if (hasPermission("manage_users"))

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDeleteDialog(item["_id"]);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
