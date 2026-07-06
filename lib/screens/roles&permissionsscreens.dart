import 'package:flutter/material.dart';
import '../widgets/mainlayout.dart';


class RolesAndPermissionsScreens extends StatelessWidget {
  const RolesAndPermissionsScreens({super.key});

  

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Roles & Permissions",
      body: SingleChildScrollView(
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Manage system roles and access levels",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                ElevatedButton.icon(
                  onPressed: () {},
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
                )
              ],
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: const [

                RoleCard(
                  roleName: "Super Admin",
                  description: "Full system access",
                  isSystem: true,
                  permissions: [
                    "roles",
                    "users",
                    "residents",
                    "fees",
                    "inventory",
                    "attendance",
                    "payments",
                    "reports",
                    "settings",
                    "hostel",
                  ],
                ),

              ],
            )
          ],
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String roleName;
  final String description;
  final bool isSystem;
  final List<String> permissions;

  const RoleCard({
    super.key,
    required this.roleName,
    required this.description,
    required this.isSystem,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {

    final visiblePermissions = permissions.take(4).toList();

    return Container(
      width: 320,
      height: 310,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
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
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
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
                (e) => Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(e),
                ),
              ),

              if (permissions.length > 4)
                Chip(
                  backgroundColor: Colors.indigo.shade50,
                  label: Text(
                    "+${permissions.length - 4} more",
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const Spacer(),

          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.edit_square,
                color: Colors.blue,
              ),
            ),
          )
        ],
      ),
    );
  }
}