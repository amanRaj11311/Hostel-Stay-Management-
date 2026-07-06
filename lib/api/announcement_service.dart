import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementService {
  static const String baseUrl =
      "https://nia.hostelapi.dcstechnosis.com/api";

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  // Get All Announcements
  static Future getAnnouncements() async {
    final response = await http.get(
      Uri.parse("$baseUrl/announcements"),
      headers: await getHeaders(),
    );

    print("Status Code : ${response.statusCode}");
    print("Response : ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  // Get Announcement By ID
  static Future getAnnouncementById(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/announcements/$id"),
      headers: await getHeaders(),
    );

    print("Status Code : ${response.statusCode}");
    print("Response : ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  // Create Announcement
  static Future createAnnouncement(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/announcements"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code : ${response.statusCode}");
    print("Response : ${response.body}");

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  // Update Announcement
  static Future updateAnnouncement(
      String id,
      Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/announcements/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Status Code : ${response.statusCode}");
    print("Response : ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  // Delete Announcement
  static Future deleteAnnouncement(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/announcements/$id"),
      headers: await getHeaders(),
    );

    print("Status Code : ${response.statusCode}");
    print("Response : ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}