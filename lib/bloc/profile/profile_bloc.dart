import 'package:adam/data/models/profile_model.dart';
import 'package:adam/data/repositories/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// =======================================================
/// EVENTS
/// =======================================================

abstract class ProfileEvent {}

class FetchProfileEvent extends ProfileEvent {}

/// =======================================================
/// STATES
/// =======================================================

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;

  ProfileLoaded(this.profile);
}

class ProfileFailure extends ProfileState {
  final String message;

  ProfileFailure(this.message);
}

/// =======================================================
/// BLOC
/// =======================================================

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({
    required this.repository,
  }) : super(ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
  }

  /// =======================================================
  /// FETCH PROFILE
  /// =======================================================

  Future<void> _onFetchProfile(
      FetchProfileEvent event,
      Emitter<ProfileState> emit,
      ) async {
    try {
      print("========== PROFILE BLOC START ==========");

      emit(ProfileLoading());

      print("⏳ CALLING PROFILE REPOSITORY...");

      final profile = await repository.fetchProfile();

      print("✅ PROFILE FETCH SUCCESS");

      print("👤 USER ID ===== ${profile.userId}");
      print("🎂 AGE ===== ${profile.age}");
      print("⚧ GENDER ===== ${profile.gender}");
      print("⚖ WEIGHT ===== ${profile.weight}");
      print("📏 HEIGHT ===== ${profile.height}");
      print("🩸 HBA1C ===== ${profile.hba1c}");
      print("🏃 ACTIVITY LEVEL ===== ${profile.activityLevel}");
      print("🥗 DIET ===== ${profile.dietRestrictions}");

      emit(ProfileLoaded(profile));

      print("========== PROFILE BLOC END ==========");
    } catch (e) {
      print("❌ PROFILE BLOC ERROR ===== $e");

      emit(
        ProfileFailure(
          e.toString().replaceAll("Exception: ", ""),
        ),
      );
    }
  }
}