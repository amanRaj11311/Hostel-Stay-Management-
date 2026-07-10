import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class UserService {
  
  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  // Get All Users
  static Future getUsers() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/users"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load users");
    }
  }

  // Create User
  static Future createUser(
      Map<String, dynamic> body) async {

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/users"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("User creation failed");
    }
  }

  // Get Single User
  static Future getUser(String id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/users/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("User not found");
    }
  }

  // Update User
  static Future updateUser(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/users/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("User update failed");
    }
  }

  // Delete User
  static Future deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/users/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("User delete failed");
    }
  }

  // Reset Password
  static Future resetPassword(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/users/$id/reset-password"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Password reset failed");
    }
  }
}