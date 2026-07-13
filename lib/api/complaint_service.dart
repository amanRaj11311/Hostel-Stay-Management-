import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ComplaintService {
  

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  // Get Complaint Stats
  static Future getComplaintStats() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/complaints/stats"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load Complaint Stats");
    }
  }

  // Get All Complaints
  static Future getComplaints() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/complaints"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load Complaints");
    }
  }

  // Create Complaint
  static Future createComplaint(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/complaints"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Complaint creation failed");
    }
  }

  // Get Single Complaint
  static Future getComplaint(String id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/complaints/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Complaint not found");
    }
  }

  // Update Complaint
  static Future updateComplaint(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/complaints/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Complaint update failed");
    }
  }

  // Delete Complaint
  static Future deleteComplaint(String id) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/complaints/$id"),
      headers: await getHeaders(),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Complaint delete failed");
    }
  }

  // Update Complaint Status
  static Future updateStatus(
      String id,
      Map<String, dynamic> body) async {

    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/complaints/$id/status"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Status update failed");
    }
  }
}