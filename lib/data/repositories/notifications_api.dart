import 'dart:convert';
import 'dart:io';
import 'package:adam/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationApi {
  static Future<void> registerToken({
    required String jwt,
    required String playerId,
    required String userId,
  }) async {
    try {
      const url = ApiEndpoints.registerNotificationToken;

      print("🚀 REGISTER TOKEN API CALLED");
      print("🌐 URL: $url");
      print("🔑 JWT: ${jwt.substring(0, 20)}...");
      print("👤 userId: $userId");
      print("📱 playerId: $playerId");
      print("📦 platform: ${Platform.isIOS ? "ios" : "android"}");

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $jwt",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "device_token": playerId,
              "platform": Platform.isIOS ? "ios" : "android",
            }),
          )
          .timeout(const Duration(seconds: 30));

      print("📡 RESPONSE RECEIVED");
      print("📊 Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("✅ TOKEN REGISTERED SUCCESSFULLY");
      } else {
        print("❌ TOKEN REGISTRATION FAILED");
      }
    } catch (e, stack) {
      print("❌ REGISTER TOKEN ERROR: $e");
      print("📚 STACKTRACE: $stack");
    }
  }

  static Future<void> unregisterToken(String playerId) async {
    try {
      print("══════════ UNREGISTER TOKEN START ══════════");

      print("📦 Getting SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      print("🔑 ACCESS TOKEN FOUND: ${token != null}");

      if (token == null || token.isEmpty) {
        print("❌ TOKEN IS NULL");
        return;
      }

      print("🆔 PLAYER ID ===== $playerId");

      final url =
          "${ApiEndpoints.unregisterNotificationToken}?device_token=$playerId";

      print("🌐 API URL ===== $url");

      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

      print("📨 HEADERS ===== $headers");

      final body = jsonEncode({"device_token": playerId});

      print("📦 REQUEST BODY ===== $body");

      print("🚀 SENDING DELETE REQUEST...");

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print("══════════ UNREGISTER RESPONSE ══════════");
      print("📡 STATUS CODE ===== ${response.statusCode}");
      print("📦 RESPONSE BODY ===== ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ TOKEN UNREGISTERED SUCCESSFULLY");
      } else {
        print("❌ FAILED TO UNREGISTER TOKEN");
      }

      print("══════════ UNREGISTER TOKEN END ══════════");
    } catch (e) {
      print("❌ UNREGISTER TOKEN ERROR ===== $e");
    }
  }
}
