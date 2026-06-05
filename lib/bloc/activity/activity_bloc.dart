// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../../data/models/activity_model.dart';
// import '../../data/repositories/activity_repository.dart';
//
// /// =======================================================
// /// EVENTS
// /// =======================================================
//
// abstract class ActivityEvent {}
//
// class SubmitActivityEvent extends ActivityEvent {
//   final ActivityLog activity;
//
//   SubmitActivityEvent(this.activity);
// }
//
// /// =======================================================
// /// STATES
// /// =======================================================
//
// abstract class ActivityState {}
//
// class ActivityInitial extends ActivityState {}
//
// class ActivityLoading extends ActivityState {}
//
// class ActivitySuccess extends ActivityState {}
//
// class ActivityFailure extends ActivityState {
//   final String message;
//
//   ActivityFailure(this.message);
// }
//
// /// =======================================================
// /// BLOC
// /// =======================================================
//
// class ActivityBloc
//     extends Bloc<ActivityEvent, ActivityState> {
//
//   final ActivityRepository repository;
//
//   ActivityBloc({
//     required this.repository,
//   }) : super(ActivityInitial()) {
//
//     on<SubmitActivityEvent>(
//       _submitActivity,
//     );
//   }
//
//   Future<void> _submitActivity(
//       SubmitActivityEvent event,
//       Emitter<ActivityState> emit,
//       ) async {
//
//     try {
//
//       emit(ActivityLoading());
//
//       print("🚀 API CALL STARTED");
//
//       final success =
//       await repository.submitActivity(
//         event.activity,
//       );
//
//       print("✅ API RESULT: $success");
//
//       if (success) {
//
//         emit(ActivitySuccess());
//
//       } else {
//
//         emit(
//           ActivityFailure(
//             "Failed to save activity",
//           ),
//         );
//       }
//
//     } catch (e) {
//
//       print("❌ BLOC ERROR: $e");
//
//       emit(
//         ActivityFailure(
//           e.toString(),
//         ),
//       );
//     }
//   }
// }
import 'package:adam/data/models/activity_model.dart';
import 'package:adam/data/repositories/activity_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// =======================================================
/// EVENTS
/// =======================================================

abstract class ActivityEvent {}

class SubmitActivityEvent extends ActivityEvent {
  final ActivityLogModel activity;

  SubmitActivityEvent(this.activity);
}

class FetchTodayActivitiesEvent extends ActivityEvent {}

/// =======================================================
/// STATES
/// =======================================================

abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivitySuccess extends ActivityState {
  final List<ActivityHistoryModel> activities;

  ActivitySuccess(this.activities);
}

class ActivityFailure extends ActivityState {
  final String message;

  ActivityFailure(this.message);
}

/// =======================================================
/// BLOC
/// =======================================================

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;

  ActivityBloc({required this.repository}) : super(ActivityInitial()) {
    on<SubmitActivityEvent>(_submitActivity);

    on<FetchTodayActivitiesEvent>(_fetchTodayActivities);
  }

  /// =======================================================
  /// SUBMIT ACTIVITY
  /// =======================================================

  Future<void> _submitActivity(
    SubmitActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());

      print("🚀 ACTIVITY LOG API STARTED");

      await repository.logActivity(event.activity);

      print("✅ ACTIVITY LOGGED SUCCESS");

      /// Fetch updated list after save
      final activities = await repository.fetchTodayActivities();

      emit(ActivitySuccess(activities));
    } catch (e) {
      print("❌ BLOC ERROR: $e");

      emit(ActivityFailure(e.toString()));
    }
  }

  /// =======================================================
  /// FETCH TODAY ACTIVITIES
  /// =======================================================

  Future<void> _fetchTodayActivities(
    FetchTodayActivitiesEvent event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());

      print("🚀 FETCH ACTIVITIES API STARTED");

      final activities = await repository.fetchTodayActivities();

      print("✅ ACTIVITIES FETCHED");

      emit(ActivitySuccess(activities));
    } catch (e) {
      print("❌ FETCH ERROR: $e");

      emit(ActivityFailure(e.toString()));
    }
  }
}
