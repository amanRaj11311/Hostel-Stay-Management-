import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class RoomService {
  
  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${prefs.getString("token")}",
    };
  }

  /// GET /rooms
  static Future<dynamic> getRooms() async {
  final response = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/rooms"),
    headers: await getHeaders(),
  );

  print("Rooms Status Code: ${response.statusCode}");
  print("Rooms Response: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(response.body);
  }
}



  /// GET /rooms/available
  static Future<dynamic> getAvailableRooms() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/rooms/available"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /rooms/stats
  static Future<dynamic> getRoomStats() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/rooms/stats"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// GET /rooms/{id}
  static Future<dynamic> getRoomById(String id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/rooms/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// POST /rooms
  static Future<dynamic> createRoom(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/rooms"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// PUT /rooms/{id}
  static Future<dynamic> updateRoom(
      String id,
      Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/rooms/$id"),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }

  /// DELETE /rooms/{id}
  static Future<dynamic> deleteRoom(String id) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/rooms/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"]);
    }
  }
}