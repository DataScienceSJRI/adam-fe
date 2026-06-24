import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adam/service/token_manager.dart';
import 'package:adam/ui/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_logger.dart';
import 'navigation_service.dart';

class ApiService {
  final String baseUrl = "https://datatools.sjri.res.in/ADAM/api/";
  final Duration timeoutDuration = const Duration(seconds: 15);

  final http.Client _client = LoggingClient();

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
  }

  Future<dynamic> _safeNetworkCall(
    Future<http.Response> Function() networkRequest,
  ) async {
    try {
      final response = await networkRequest().timeout(timeoutDuration);
      return _processResponse(response);
    } on TimeoutException {
      throw const FormatException(
        'The connection timed out. Please try again.',
      );
    } on SocketException catch (e) {
      throw HttpException(
        'No Internet connection or server unreachable. (${e.message})',
      );
    } on HandshakeException {
      throw const HttpException(
        'Secure connection failed (SSL/TLS handshake error).',
      );
    } on FormatException {
      throw const FormatException(
        'Bad response format. The server returned unparsable data.',
      );
    } on http.ClientException catch (e) {
      throw HttpException('Network client request aborted: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected network error occurred: $e');
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    return _safeNetworkCall(
      () => _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._getHeaders(), ...?headers},
      ),
    );
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _safeNetworkCall(
      () => _client.post(
        Uri.parse('$baseUrl$endpoint'),

        headers: {..._getHeaders(), ...?headers},

        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _safeNetworkCall(
      () => _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._getHeaders(), ...?headers},
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _safeNetworkCall(
      () => _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._getHeaders(), ...?headers},
      ),
    );
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _safeNetworkCall(
      () => _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._getHeaders(), ...?headers},
        body: jsonEncode(body),
      ),
    );
  }

  dynamic _processResponse(http.Response response) async {
    final int statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String serverErrorMessage = '';
    try {
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        serverErrorMessage =
            errorBody['message'] ?? errorBody['error'] ?? response.body;
      }
    } catch (_) {
      serverErrorMessage = response.body;
    }

    final String errorContext = serverErrorMessage.isNotEmpty
        ? ': $serverErrorMessage'
        : '';

    if (statusCode >= 300 && statusCode < 400) {
      throw HttpException('Redirection Error ($statusCode)$errorContext');
    } else if (statusCode >= 400 && statusCode < 500) {
      switch (statusCode) {
        case 400:
          throw HttpException('Bad Request ($statusCode)$errorContext');
        case 401:
          await _logoutUser();
          throw HttpException(
            'Unauthorized ($statusCode). Please log in again.$errorContext',
          );
        case 403:
          throw HttpException(
            'Forbidden ($statusCode). You do not have permission.$errorContext',
          );
        case 404:
          throw HttpException(
            'Not Found ($statusCode). The requested resource does not exist.$errorContext',
          );
        default:
          throw HttpException('Client Error ($statusCode)$errorContext');
      }
    } else if (statusCode >= 500 && statusCode < 600) {
      throw HttpException('Server Error ($statusCode)$errorContext');
    } else {
      throw HttpException('Unknown HTTP Error ($statusCode)$errorContext');
    }
  }

  Future<void> _logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();
      await Supabase.instance.client.auth.signOut();

      NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print("❌ LOGOUT ERROR ===== $e");
    }
  }
}
