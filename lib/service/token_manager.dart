import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';

class TokenManager {
  Completer<String?>? _refreshCompleter;

  Future<String?> refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      debugPrint("🔄 [TokenManager] Refreshing token with: $refreshToken");

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      debugPrint("📡 [TokenManager] Refresh Status: ${response.statusCode}");
      debugPrint("📦 [TokenManager] Refresh Body: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];

        await prefs.setString('access_token', accessToken);
        await prefs.setInt(
          'token_expiry',
          DateTime.now().add(const Duration(seconds: 3600)).millisecondsSinceEpoch,
        );

        if (data['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }

        return accessToken;
      }
      return null;
    } catch (e) {
      debugPrint("🚨 [TokenManager] Refresh Token Error: $e");
      return null;
    }
  }

  Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = prefs.getInt('token_expiry') ?? 0;

    debugPrint("🔍 [TokenManager] Checking validity. Current: $now, Expiry: $expiry");

    final buffer = const Duration(minutes: 5).inMilliseconds;

    if (now >= expiry - buffer) {
      debugPrint("⚠️ [TokenManager] Token is expired or expiring soon.");

      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        debugPrint("⏳ [TokenManager] Waiting for existing refresh...");
        return _refreshCompleter!.future;
      }

      _refreshCompleter = Completer<String?>();

      try {
        // FIXED: Called your actual method name here
        final newToken = await refreshAccessToken();
        _refreshCompleter!.complete(newToken);
        return newToken;
      } catch (e) {
        _refreshCompleter!.complete(null);
        rethrow;
      } finally {
        _refreshCompleter = null;
      }
    }

    debugPrint("✨ [TokenManager] Token is valid.");
    return prefs.getString('access_token');
  }
}