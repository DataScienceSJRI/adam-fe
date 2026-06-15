import 'package:adam/data/models/activity_model.dart';
import 'package:adam/data/repositories/activity_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ActivityEvent {}

class SubmitActivityEvent extends ActivityEvent {
  final ActivityLogModel activity;
  final DateTime date;

  SubmitActivityEvent(this.activity, this.date);
}

class FetchTodayActivitiesEvent extends ActivityEvent {
  final DateTime date;

  FetchTodayActivitiesEvent({required this.date});
}

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

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;

  ActivityBloc({required this.repository}) : super(ActivityInitial()) {
    on<SubmitActivityEvent>(_submitActivity);

    on<FetchTodayActivitiesEvent>(_fetchTodayActivities);
  }

  Future<void> _submitActivity(
    SubmitActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());

      print("🚀 ACTIVITY LOG API STARTED");

      await repository.logActivity(event.activity);

      print("✅ ACTIVITY LOGGED SUCCESS");

      final activities = await repository.fetchTodayActivities(event.date);

      emit(ActivitySuccess(activities));
    } catch (e) {
      print("❌ BLOC ERROR: $e");

      emit(ActivityFailure(e.toString()));
    }
  }

  Future<void> _fetchTodayActivities(
    FetchTodayActivitiesEvent event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());

      print("🚀 FETCH ACTIVITIES API STARTED");

      final activities = await repository.fetchTodayActivities(event.date);

      print("✅ ACTIVITIES FETCHED");

      emit(ActivitySuccess(activities));
    } catch (e) {
      print("❌ FETCH ERROR: $e");

      emit(ActivityFailure(e.toString()));
    }
  }
}
