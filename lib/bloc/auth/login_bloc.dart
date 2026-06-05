// import 'package:adam/data/repositories/auth_repository.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // --- EVENTS ---
// abstract class LoginEvent {}
//
// class LoginSubmitted extends LoginEvent {
//   final String participantId;
//   final String password;
//
//   LoginSubmitted({
//     required this.participantId,
//     required this.password,
//   });
// }
//
// // --- STATES ---
// abstract class LoginState {}
//
// class LoginInitial extends LoginState {}
//
// class LoginLoading extends LoginState {}
//
// class LoginSuccess extends LoginState {
//   final Map<String, dynamic> userData;
//
//   LoginSuccess(this.userData);
// }
//
// class LoginFailure extends LoginState {
//   final String errorMessage;
//
//   LoginFailure(this.errorMessage);
// }
//
// // --- BLOC ---
// class LoginBloc extends Bloc<LoginEvent, LoginState> {
//   final AuthRepository authRepository;
//
//   LoginBloc({
//     required this.authRepository,
//   }) : super(LoginInitial()) {
//     on<LoginSubmitted>((event, emit) async {
//       if (event.participantId.isEmpty ||
//           event.password.isEmpty) {
//         emit(LoginFailure("Please fill out all fields."));
//         return;
//       }
//
//       emit(LoginLoading());
//
//       try {
//         final userData = await authRepository.login(
//           event.participantId,
//           event.password,
//         );
//
//         /// Save tokens in SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//
//         await prefs.setString(
//           'access_token',
//           userData['access_token'] ?? '',
//         );
//
//         await prefs.setString(
//           'refresh_token',
//           userData['refresh_token'] ?? '',
//         );
//
//         emit(LoginSuccess(userData));
//       } catch (e) {
//         final cleanMsg =
//         e.toString().replaceAll('Exception: ', '');
//
//         emit(LoginFailure(cleanMsg));
//       }
//     });
//   }
// }
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

/// =======================================================
/// EVENTS
/// =======================================================

abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String participantId;
  final String password;

  LoginSubmitted({required this.participantId, required this.password});
}

/// =======================================================
/// STATES
/// =======================================================

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

/// =======================================================
/// LOGIN BLOC
/// =======================================================
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  /// =========================================================
  /// LOGIN EVENT
  /// =========================================================

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    /// VALIDATION
    if (event.participantId.trim().isEmpty || event.password.trim().isEmpty) {
      emit(LoginFailure("Please fill out all fields."));
      return;
    }

    emit(LoginLoading());

    try {
      /// =====================================================
      /// LOGIN API
      /// =====================================================

      final userData = await authRepository.login(
        event.participantId,
        event.password,
      );

      debugPrint("✅ LOGIN RESPONSE ===== $userData");

      /// =====================================================
      /// SUPABASE LOGIN
      /// =====================================================

      await Supabase.instance.client.auth.signInWithPassword(
        email: event.participantId,
        password: event.password,
      );

      debugPrint("✅ SUPABASE LOGIN SUCCESS");

      /// =====================================================
      /// SHARED PREFERENCES
      /// =====================================================

      final prefs = await SharedPreferences.getInstance();

      /// SAVE COMPLETE USER DATA
      await prefs.setString('user_data', jsonEncode(userData));

      /// ACCESS TOKEN
      final String accessToken = userData['access_token'] ?? '';

      await prefs.setString('access_token', accessToken);

      debugPrint("🔑 ACCESS TOKEN SAVED");

      /// REFRESH TOKEN
      final String refreshToken = userData['refresh_token'] ?? '';

      await prefs.setString('refresh_token', refreshToken);

      debugPrint("🔄 REFRESH TOKEN SAVED");

      /// =====================================================
      /// ONESIGNAL LOGIN
      /// =====================================================

      try {
        debugPrint("🚀 Logging into OneSignal: ${event.participantId}");

        /// LOGIN TO ONESIGNAL
        await OneSignal.login(event.participantId);

        debugPrint("✅ OneSignal Login Success");

        /// TRY EXISTING PLAYER ID
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

        /// OBSERVER FOR FUTURE TOKEN CHANGES
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

      /// =====================================================
      /// SUCCESS
      /// =====================================================

      emit(LoginSuccess(userData));
    } catch (e) {
      // 1. Keep this so YOU can still see the exact error in your dev console
      debugPrint("❌ LOGIN ERROR ===== $e");

      // 2. Determine the user-friendly message
      String userMessage;
      final errorString = e.toString();

      if (errorString.contains('FormatException') && errorString.contains('timed out')) {
        userMessage = "The connection timed out. Please check your internet and try again.";
      } else if (errorString.contains('SocketException')) {
        userMessage = "No internet connection detected.";
      } else {
        // Fallback: strip 'Exception: ' for any other unexpected errors
        userMessage = errorString.replaceAll('Exception: ', '');
      }

      // 3. Emit the clean message to the UI
      emit(LoginFailure(userMessage));
    }
  }

  /// =========================================================
  /// REGISTER PLAYER ID API
  /// =========================================================

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

// class LoginBloc extends Bloc<LoginEvent, LoginState> {
//   final AuthRepository authRepository;
//
//   LoginBloc({required this.authRepository}) : super(LoginInitial()) {
//     on<LoginSubmitted>((event, emit) async {
//       /// VALIDATION
//       if (event.participantId.isEmpty || event.password.isEmpty) {
//         emit(LoginFailure("Please fill out all fields."));
//         return;
//       }
//
//       emit(LoginLoading());
//
//       try {
//         /// ===================================================
//         /// LOGIN API
//         /// ===================================================
//
//         final userData = await authRepository.login(
//           event.participantId,
//           event.password,
//         );
//
//         print("✅ LOGIN RESPONSE ===== $userData");
//         await Supabase.instance.client.auth.signInWithPassword(
//           email: event.participantId,
//           password: event.password,
//         );
//
//         print("✅ SUPABASE LOGIN SUCCESS");
//
//         /// ===================================================
//         /// SHARED PREFERENCES
//         /// ===================================================
//
//         final prefs = await SharedPreferences.getInstance();
//
//         /// SAVE COMPLETE USER DATA
//         await prefs.setString('user_data', jsonEncode(userData));
//
//         /// ACCESS TOKEN
//         final String accessToken = userData['access_token'] ?? '';
//
//         await prefs.setString('access_token', accessToken);
//
//         print("🔑 ACCESS TOKEN SAVED");
//
//         /// REFRESH TOKEN
//         final String refreshToken = userData['refresh_token'] ?? '';
//
//         await prefs.setString('refresh_token', refreshToken);
//
//         print("🔄 REFRESH TOKEN SAVED");
//
//         /// ===================================================
//         /// ONESIGNAL LOGIN
//         /// ===================================================
//
//         try {
//           /// Login user to OneSignal
//           await OneSignal.login(event.participantId);
//           print("🚀 Logging in to OneSignal with user ID: ${event.participantId}");
//
//           print("✅ OneSignal Login Success");
//
//           /// Wait briefly so player id gets generated
//           await Future.delayed(const Duration(seconds: 2));
//
//           /// GET PLAYER ID
//           final String? playerId = OneSignal.User.pushSubscription.id;
//
//           print("📲 PLAYER ID ===== $playerId");
//
//           /// SAVE PLAYER ID
//           if (playerId != null) {
//             await prefs.setString('player_id', playerId);
//           }
//
//           /// ===================================================
//           /// REGISTER NOTIFICATION TOKEN API
//           /// ===================================================
//
//           if (playerId != null &&
//               playerId.isNotEmpty &&
//               accessToken.isNotEmpty) {
//             try {
//               final response = await http.post(
//                 Uri.parse(ApiEndpoints.registerNotificationToken),
//                 headers: {
//                   'Content-Type': 'application/json',
//                   'Authorization': 'Bearer $accessToken',
//                 },
//                 body: jsonEncode({
//                   "player_id": playerId,
//                   "user_id": event.participantId,
//                 }),
//               );
//
//               print("📡 REGISTER TOKEN STATUS ===== ${response.statusCode}");
//
//               print("📦 REGISTER TOKEN RESPONSE ===== ${response.body}");
//
//               if (response.statusCode == 200 || response.statusCode == 201) {
//                 print("✅ NOTIFICATION TOKEN REGISTERED SUCCESSFULLY");
//               } else {
//                 print("❌ FAILED TO REGISTER TOKEN");
//               }
//             } catch (e) {
//               print("❌ REGISTER TOKEN API ERROR ===== $e");
//             }
//           } else {
//             print("❌ PLAYER ID OR ACCESS TOKEN MISSING");
//           }
//         } catch (e) {
//           print("❌ OneSignal Error ===== $e");
//         }
//
//         /// ===================================================
//         /// SUCCESS
//         /// ===================================================
//
//         emit(LoginSuccess(userData));
//       } catch (e) {
//         print("❌ LOGIN ERROR ===== $e");
//
//         final cleanMsg = e.toString().replaceAll('Exception: ', '');
//
//         emit(LoginFailure(cleanMsg));
//       }
//     });
//   }
// }
