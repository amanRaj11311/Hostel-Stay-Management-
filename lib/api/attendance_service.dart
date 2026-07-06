import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String baseUrl =
      "https://nia.hostelapi.dcstechnosis.com/api";

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// GET /attendance
  static Future<dynamic> getAttendance() async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /attendance/today
  static Future<dynamic> getTodayAttendance() async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/today"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /attendance/stats
  static Future<dynamic> getAttendanceStats() async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/stats"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /attendance/resident/{id}
  static Future<dynamic> getAttendanceByResident(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/resident/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// POST /attendance/checkin
  static Future<dynamic> checkIn(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/attendance/checkin"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PATCH /attendance/{id}/checkout
  static Future<dynamic> checkOut(String id) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/attendance/$id/checkout"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PUT /attendance/{id}
  static Future<dynamic> updateAttendance(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/attendance/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// DELETE /attendance/{id}
  static Future<dynamic> deleteAttendance(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/attendance/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}