import 'package:shared_preferences/shared_preferences.dart';

class PermissionHelper {
  static Future<bool> hasPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();

    final permissions = prefs.getStringList("permissions") ?? [];

    return permissions.contains(permission);
  }
}