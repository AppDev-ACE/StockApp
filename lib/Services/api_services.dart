import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://daksh-ldw4.onrender.com"; // web testing

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> getPortfolio() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/portfolio"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body)
    };
  }

  static Future<Map<String, dynamic>> getPrices() async {
    final response =
        await http.get(Uri.parse("$baseUrl/prices"));

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body)
    };
  }
}