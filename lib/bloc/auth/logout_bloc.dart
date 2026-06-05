import 'package:adam/data/repositories/notifications_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/logout_repository.dart';

abstract class LogoutEvent {}

class LogoutRequested extends LogoutEvent {}

abstract class LogoutState {}

class LogoutInitial extends LogoutState {}

class LogoutLoading extends LogoutState {}

class LogoutSuccess extends LogoutState {}

class LogoutFailure extends LogoutState {
  final String message;

  LogoutFailure(this.message);
}

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final LogoutRepository repository;

  LogoutBloc({required this.repository}) : super(LogoutInitial()) {
    on<LogoutRequested>(_logout);
  }

  Future<void> _logout(LogoutRequested event, Emitter<LogoutState> emit) async {
    try {
      emit(LogoutLoading());

      final currentId = OneSignal.User.pushSubscription.id;

      if (currentId != null) {
        await NotificationApi.unregisterToken(currentId);
      }

      final success = await repository.logout();

      await Supabase.instance.client.auth.signOut();

      if (success) {
        emit(LogoutSuccess());
      } else {
        emit(LogoutFailure("Logout failed"));
      }
    } catch (e) {
      print("❌ LOGOUT EXCEPTION ===== $e");

      emit(LogoutFailure(e.toString()));
    }
  }
}
