import 'package:adam/data/models/dashboard_model.dart';
import 'package:adam/data/repositories/dashboard_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// =======================================================
/// EVENTS
/// =======================================================

abstract class DashboardEvent {}

class GetDashboardEvent extends DashboardEvent {}

/// =======================================================
/// STATES
/// =======================================================

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardModel dashboardData;

  DashboardLoaded({
    required this.dashboardData,
  });
}

class DashboardFailure extends DashboardState {
  final String message;

  DashboardFailure({
    required this.message,
  });
}

/// =======================================================
/// BLOC
/// =======================================================

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({
    required this.repository,
  }) : super(DashboardInitial()) {
    on<GetDashboardEvent>(_onGetDashboard);
  }

  Future<void> _onGetDashboard(
      GetDashboardEvent event,
      Emitter<DashboardState> emit,
      ) async {
    emit(DashboardLoading());

    try {
      final DashboardModel response =
      await repository.fetchDashboardData();

      emit(
        DashboardLoaded(
          dashboardData: response,
        ),
      );
    } catch (e) {
      emit(
        DashboardFailure(
          message: e.toString(),
        ),
      );
    }
  }
}