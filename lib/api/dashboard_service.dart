import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class DashboardService {

  

  static Future<Map<String,String>> getHeaders() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return {
      "Content-Type":"application/json",
      "Authorization":"Bearer ${prefs.getString("token")}"
    };
  }

  static Future getDashboardStats() async {

  final response = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/dashboard/stats"),
    headers: await getHeaders(),
  );

  print("Status Code : ${response.statusCode}");
  print("Response : ${response.body}");

  return jsonDecode(response.body);
}

static Future getRecentAttendance() async {

  final response = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/dashboard/recent-attendance"),
    headers: await getHeaders(),
  );

  print("Attendance Status : ${response.statusCode}");
  print("Attendance Data : ${response.body}");

  return jsonDecode(response.body);
}

static Future getRecentVisitors() async {
  final response = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/dashboard/recent-visitors"),
    headers: await getHeaders(),
  );

  print("Visitors Status : ${response.statusCode}");
  print("Visitors Data : ${response.body}");

  return jsonDecode(response.body);
}
static Future getRecentAnnouncements() async {
  final response = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/dashboard/recent-announcements"),
    headers: await getHeaders(),
  );

  return jsonDecode(response.body);
}

}