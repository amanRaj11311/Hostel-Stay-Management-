import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class FeeService {
 

  
  /// Headers
  
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// ============================
  /// GET /fees
  /// Get All Fees
  /// ============================
  static Future<dynamic> getFees() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/fees"),
      headers: await getHeaders(),
    );

    print("Fees Status: ${response.statusCode}");
    print("Fees Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// GET /fees/stats
  /// ============================
  static Future<dynamic> getFeeStats() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/fees/stats"),
      headers: await getHeaders(),
    );

    print("Fee Stats: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// GET /fees/overdue
  /// ============================
  static Future<dynamic> getOverdueFees() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/fees/overdue"),
      headers: await getHeaders(),
    );

    print("Overdue Fees: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// GET /fees/resident/{residentId}
  /// ============================
  static Future<dynamic> getResidentFees(String residentId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/fees/resident/$residentId"),
      headers: await getHeaders(),
    );

    print("Resident Fees: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// GET /fees/{id}
  /// ============================
  static Future<dynamic> getFeeById(String id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/fees/$id"),
      headers: await getHeaders(),
    );

    print("Fee Details: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// POST /fees
  /// ============================
  static Future<dynamic> createFee(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/fees"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Create Fee: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// PUT /fees/{id}
  /// ============================
  static Future<dynamic> updateFee(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/fees/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Update Fee: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// DELETE /fees/{id}
  /// ============================
  static Future<dynamic> deleteFee(String id) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/fees/$id"),
      headers: await getHeaders(),
    );

    print("Delete Fee: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// ============================
  /// PATCH /fees/{id}/mark-paid
  /// ============================
  static Future<dynamic> markFeePaid(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/fees/$id/mark-paid"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    print("Mark Fee Paid: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}