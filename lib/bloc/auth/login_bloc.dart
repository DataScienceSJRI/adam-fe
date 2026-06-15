import 'dart:convert';
import 'dart:io';

import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/repositories/auth_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String participantId;
  final String password;

  LoginSubmitted({required this.participantId, required this.password});
}

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final Map<String, dynamic> userData;

  LoginSuccess(this.userData);
}

class LoginFailure extends LoginState {
  final String errorMessage;

  LoginFailure(this.errorMessage);
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (event.participantId.trim().isEmpty || event.password.trim().isEmpty) {
      emit(LoginFailure("Please fill out all fields."));
      return;
    }

    emit(LoginLoading());

    try {
      final userData = await authRepository.login(
        event.participantId,
        event.password,
      );

      debugPrint("✅ LOGIN RESPONSE ===== $userData");

      await Supabase.instance.client.auth.signInWithPassword(
        email: event.participantId,
        password: event.password,
      );

      debugPrint("✅ SUPABASE LOGIN SUCCESS");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_data', jsonEncode(userData));

      final String accessToken = userData['access_token'] ?? '';

      await prefs.setString('access_token', accessToken);

      debugPrint("🔑 ACCESS TOKEN SAVED");

      final String refreshToken = userData['refresh_token'] ?? '';

      await prefs.setString('refresh_token', refreshToken);

      debugPrint("🔄 REFRESH TOKEN SAVED ${refreshToken}");
      await prefs.setInt(
        'token_expiry',
        DateTime.now()
            .add(const Duration(seconds: 3600))
            .millisecondsSinceEpoch,
      );

      debugPrint("⏰ TOKEN EXPIRY SAVED");

      try {
        debugPrint("🚀 Logging into OneSignal: ${event.participantId}");

        await OneSignal.login(event.participantId);

        debugPrint("✅ OneSignal Login Success");

        final existingPlayerId = OneSignal.User.pushSubscription.id;

        debugPrint("📲 EXISTING PLAYER ID ===== $existingPlayerId");

        if (existingPlayerId != null && existingPlayerId.isNotEmpty) {
          await prefs.setString('player_id', existingPlayerId);

          await _registerPlayerId(
            playerId: existingPlayerId,
            accessToken: accessToken,
            userId: event.participantId,
          );
        }

        OneSignal.User.pushSubscription.addObserver((state) async {
          final playerId = state.current.id;

          debugPrint("🔄 OBSERVER PLAYER ID ===== $playerId");

          if (playerId != null && playerId.isNotEmpty) {
            await prefs.setString('player_id', playerId);

            await _registerPlayerId(
              playerId: playerId,
              accessToken: accessToken,
              userId: event.participantId,
            );
          }
        });
      } catch (e) {
        debugPrint("❌ ONESIGNAL ERROR ===== $e");
      }

      emit(LoginSuccess(userData));
    } catch (e) {
      debugPrint("❌ LOGIN ERROR ===== $e");

      String userMessage;
      final errorString = e.toString();

      if (errorString.contains('FormatException') &&
          errorString.contains('timed out')) {
        userMessage =
            "The connection timed out. Please check your internet and try again.";
      } else if (errorString.contains('SocketException')) {
        userMessage = "No internet connection detected.";
      } else {
        userMessage = errorString.replaceAll('Exception: ', '');
      }

      emit(LoginFailure(userMessage));
    }
  }

  Future<void> _registerPlayerId({
    required String playerId,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.registerNotificationToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "device_token": playerId,
          "user_id": userId,
          "platform": Platform.isAndroid ? "android" : "ios",
        }),
      );

      debugPrint("📡 REGISTER TOKEN STATUS ===== ${response.statusCode}");

      debugPrint("📦 REGISTER TOKEN RESPONSE ===== ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ NOTIFICATION TOKEN REGISTERED");
      } else {
        debugPrint("❌ FAILED TO REGISTER TOKEN");
      }
    } catch (e) {
      debugPrint("❌ REGISTER TOKEN API ERROR ===== $e");
    }
  }
}
