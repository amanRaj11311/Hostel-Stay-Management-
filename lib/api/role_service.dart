import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RoleService  {
  static const String baseUrl =
      "https://nia.hostelapi.dcstechnosis.com/api";

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// GET /roles
  static Future<dynamic> getRoles() async {
    final response = await http.get(
      Uri.parse("$baseUrl/roles"),
      headers: await getHeaders(),
    );

    print("Roles Status Code: ${response.statusCode}");
    print("Roles Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// POST /roles
  static Future<dynamic> createRole(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/roles"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Create Role Status Code: ${response.statusCode}");
    print("Create Role Response: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PUT /roles/{id}
  static Future<dynamic> updateRole(
      String id,
      Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/roles/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Update Role Status Code: ${response.statusCode}");
    print("Update Role Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// DELETE /roles/{id}
  static Future<dynamic> deleteRole(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/roles/$id"),
      headers: await getHeaders(),
    );

    print("Delete Role Status Code: ${response.statusCode}");
    print("Delete Role Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}