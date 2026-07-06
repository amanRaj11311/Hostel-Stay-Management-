import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResidentService {
  static const String baseUrl =
      "https://nia.hostelapi.dcstechnosis.com/api";

  /// Headers
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// ============================
  /// GET /residents
  /// ============================
  static Future<dynamic> getResidents() async {
    final response = await http.get(
      Uri.parse("$baseUrl/residents"),
      headers: await getHeaders(),
    );

    print("Residents Status: ${response.statusCode}");
    print("Residents Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// GET /residents/search
  /// ============================
  /// GET /residents/search
static Future<dynamic> searchResidents(String q) async {
  final uri = Uri.parse("$baseUrl/residents/search")
      .replace(queryParameters: {
    "q": q,
  });

  final response = await http.get(
    uri,
    headers: await getHeaders(),
  );

  print("Search Residents Status: ${response.statusCode}");
  print("Search Residents Response: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(jsonDecode(response.body)["message"]);
  }
}




  /// ============================
  /// GET /residents/{id}
  /// ============================
  static Future<dynamic> getResidentById(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/residents/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// POST /residents
  /// ============================
  static Future<dynamic> createResident(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/residents"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Create Resident: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// PUT /residents/{id}
  /// ============================
  static Future<dynamic> updateResident(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/residents/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Update Resident: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// DELETE /residents/{id}
  /// ============================
  static Future<dynamic> deleteResident(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/residents/$id"),
      headers: await getHeaders(),
    );

    print("Delete Resident: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// PATCH Attendance
  /// /residents/{id}/attendance
  /// ============================
  static Future<dynamic> updateAttendance(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/residents/$id/attendance"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Attendance: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// PATCH Fee Status
  /// /residents/{id}/fee-status
  /// ============================
  static Future<dynamic> updateFeeStatus(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/residents/$id/fee-status"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Fee Status: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}