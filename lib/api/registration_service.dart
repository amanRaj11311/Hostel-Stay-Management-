import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class RegistrationService {
  

  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// GET /registrations
  static Future<dynamic> getRegistrations() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/registrations"),
      headers: await getHeaders(),
    );

    print("Registrations Status Code: ${response.statusCode}");
    print("Registrations Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /registrations/{id}
  static Future<dynamic> getRegistrationById(String id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/registrations/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// POST /registrations
  static Future<dynamic> createRegistration(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/registrations"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PUT /registrations/{id}
  static Future<dynamic> updateRegistration(
      String id,
      Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/registrations/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// DELETE /registrations/{id}
  static Future<dynamic> deleteRegistration(String id) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/registrations/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PATCH /registrations/{id}/approve
  static Future<dynamic> approveRegistration(String id) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/registrations/$id/approve"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PATCH /registrations/{id}/reject
  static Future<dynamic> rejectRegistration(String id) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/registrations/$id/reject"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}