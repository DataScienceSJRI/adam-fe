import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// =======================================================
/// EVENTS
/// =======================================================

abstract class DietRecallEvent {}

class SubmitDietRecallEvent extends DietRecallEvent {
  final String mealSlot;
  final String planId;
  final bool didEatAsPlanned;
  final List<String> recipeCodes;
  final List<String> quantities;

  SubmitDietRecallEvent({
    required this.mealSlot,
    required this.planId,
    required this.didEatAsPlanned,
    required this.recipeCodes,required this.quantities
  });
}

/// =======================================================
/// STATES
/// =======================================================

abstract class DietRecallState {}

class DietRecallInitial extends DietRecallState {}

class DietRecallLoading extends DietRecallState {}

class DietRecallSuccess extends DietRecallState {}

class DietRecallFailure extends DietRecallState {
  final String message;

  DietRecallFailure(this.message);
}

/// =======================================================
/// BLOC
/// =======================================================

class DietRecallBloc extends Bloc<DietRecallEvent, DietRecallState> {
  final DietRecallRepository repository;

  DietRecallBloc({required this.repository}) : super(DietRecallInitial()) {
    on<SubmitDietRecallEvent>((event, emit) async {
      emit(DietRecallLoading());

      try {
        await repository.logDietRecall(
          recipeCodes: event.recipeCodes,
          mealSlot: event.mealSlot,
          planId: event.planId,
          didEatAsPlanned: event.didEatAsPlanned,
          quantities: event.quantities,
        );

        emit(DietRecallSuccess());
      } catch (e) {
        emit(DietRecallFailure(e.toString()));
      }
    });
  }
}
