import 'package:adam/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogoutRepository {
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse(ApiEndpoints.logout),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📡 Logout Status: ${response.statusCode}");
      print("📦 Logout Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Logout Error: $e");

      return false;
    }
  }
}
