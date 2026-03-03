import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
    }
    return null;
  }

  static Future<dynamic> getCandles(String symbol, String range, String token) async {
    final response = await http.get(
      Uri.parse("${AppConstants.baseUrl}/candles?symbol=$symbol&range=$range"),
      headers: {
        "Authorization": token,
      },
    );

    return jsonDecode(response.body);
  }
}