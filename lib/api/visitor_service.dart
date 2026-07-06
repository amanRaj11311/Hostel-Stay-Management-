import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VisitorService {
  static const String baseUrl =
      "https://nia.hostelapi.dcstechnosis.com/api";

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  // Today's Visitors
  static Future getTodayVisitors() async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitors/today"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load today's visitors");
    }
  }

  // Get All Visitors
  static Future getVisitors() async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitors"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load visitors");
    }
  }

  // Create Visitor
  static Future createVisitor(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/visitors"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor creation failed");
    }
  }

  // Get Single Visitor
  static Future getVisitor(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitors/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor not found");
    }
  }

  // Update Visitor
  static Future updateVisitor(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.put(
      Uri.parse("$baseUrl/visitors/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor update failed");
    }
  }

  // Delete Visitor
  static Future deleteVisitor(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/visitors/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor delete failed");
    }
  }

  // Approve Visitor
  static Future approveVisitor(String id) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/visitors/$id/approve"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor approval failed");
    }
  }

  // Reject Visitor
  static Future rejectVisitor(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.patch(
      Uri.parse("$baseUrl/visitors/$id/reject"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor rejection failed");
    }
  }

  // Check Out Visitor
  static Future checkoutVisitor(String id) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/visitors/$id/checkout"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Visitor checkout failed");
    }
  }
}