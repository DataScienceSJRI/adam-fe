// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../core/constants/api_endpoints.dart';
//
// class TokenManager {
//   Completer<String?>? _refreshCompleter;
//
//   Future<String?> refreshAccessToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final refreshToken = prefs.getString('refresh_token');
//
//       debugPrint("🔄 [TokenManager] Refreshing token with: $refreshToken");
//
//       if (refreshToken == null || refreshToken.isEmpty) {
//         return null;
//       }
//
//       final response = await http.post(
//         Uri.parse(ApiEndpoints.refreshToken),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'refresh_token': refreshToken}),
//       );
//
//       debugPrint("📡 [TokenManager] Refresh Status: ${response.statusCode}");
//       debugPrint("📦 [TokenManager] Refresh Body: ${response.body}");
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final accessToken = data['access_token'];
//
//         await prefs.setString('access_token', accessToken);
//         await prefs.setInt(
//           'token_expiry',
//           DateTime.now().add(const Duration(seconds: 3600)).millisecondsSinceEpoch,
//         );
//
//         if (data['refresh_token'] != null) {
//           await prefs.setString('refresh_token', data['refresh_token']);
//         }
//
//         return accessToken;
//       }
//       return null;
//     } catch (e) {
//       debugPrint("🚨 [TokenManager] Refresh Token Error: $e");
//       return null;
//     }
//   }
//
//   Future<String?> getValidAccessToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final expiry = prefs.getInt('token_expiry') ?? 0;
//     debugPrint(
//         "Current Time = ${DateTime.now()}"
//     );
//     debugPrint(
//         "Expiry Time = ${DateTime.fromMillisecondsSinceEpoch(expiry)}"
//     );
//
//     debugPrint("🔍 [TokenManager] Checking validity. Current: $now, Expiry: $expiry");
//
//     final buffer = const Duration(minutes: 10).inMilliseconds;
//
//     if (now >= expiry - buffer) {
//       debugPrint("⚠️ [TokenManager] Token is expired or expiring soon.");
//
//       if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
//         debugPrint("⏳ [TokenManager] Waiting for existing refresh...");
//         return _refreshCompleter!.future;
//       }
//
//       _refreshCompleter = Completer<String?>();
//
//       try {
//         final newToken = await refreshAccessToken();
//         _refreshCompleter!.complete(newToken);
//         return newToken;
//       } catch (e) {
//         _refreshCompleter!.complete(null);
//         rethrow;
//       } finally {
//         _refreshCompleter = null;
//       }
//     }
//
//     debugPrint("✨ [TokenManager] Token is valid.");
//     return prefs.getString('access_token');
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';

class TokenManager {
  TokenManager._internal();
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  Completer<String?>? _refreshCompleter;

  Future<String?> refreshAccessToken() async {
    debugPrint("🔍 [TokenManager] Starting refreshAccessToken process...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("🚨 [TokenManager] No refresh token found locally. Refresh aborted.");
        return null;
      }

      debugPrint("🔄 [TokenManager] Attempting API refresh with: $refreshToken");

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      debugPrint("📡 [TokenManager] API response received. Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];

        debugPrint("💾 [TokenManager] Persisting new access token...");
        await prefs.setString('access_token', accessToken);

        // Save new expiry
        final expiryTime = DateTime.now().toUtc().add(const Duration(seconds: 3600)).millisecondsSinceEpoch;
        await prefs.setInt('token_expiry', expiryTime);
        debugPrint("⏰ [TokenManager] New expiry set for: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}");

        if (data['refresh_token'] != null) {
          debugPrint("🔄 [TokenManager] Rotating refresh token as well.");
          await prefs.setString('refresh_token', data['refresh_token']);
        }

        debugPrint("✨ [TokenManager] Token refreshed successfully.");
        return accessToken;
      }

      debugPrint("❌ [TokenManager] Server rejected refresh token: Status ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("🚨 [TokenManager] Network/Parsing Error during refresh: $e");
      return null;
    }
  }

  Future<String?> getValidAccessToken() async {
    debugPrint("📥 [TokenManager] getValidAccessToken called.");

    // Check if refresh is already in progress
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      debugPrint("⏳ [TokenManager] Awaiting ongoing refresh pipeline...");
      return _refreshCompleter!.future;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final expiry = prefs.getInt('token_expiry') ?? 0;
    final buffer = const Duration(minutes: 10).inMilliseconds;

    debugPrint("📊 [TokenManager] Checking token health: Now: $now, Expiry: $expiry, Buffer: $buffer");

    // Condition A: Access token is still valid
    if (now < (expiry - buffer)) {
      final existingToken = prefs.getString('access_token');
      if (existingToken != null && existingToken.isNotEmpty) {
        debugPrint("✅ [TokenManager] Access token is valid. Returning cached token.");
        return existingToken;
      }
    }

    // Condition B: Access token is expired/expiring soon. Trigger refresh lock.
    debugPrint("⚠️ [TokenManager] Access token expired or expiring soon. Triggering refresh pipeline...");
    _refreshCompleter = Completer<String?>();

    try {
      final newToken = await refreshAccessToken();
      debugPrint("🏁 [TokenManager] Refresh pipeline complete. Completing completer.");
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      debugPrint("❌ [TokenManager] Critical failure in refresh pipeline: $e");
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      debugPrint("🔓 [TokenManager] Resetting _refreshCompleter lock.");
      _refreshCompleter = null; // Clear lock
    }
  }

  Future<void> clearSession() async {
    debugPrint("🧹 [TokenManager] Clearing session...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
    debugPrint("✅ [TokenManager] Local session cleared.");
  }
}