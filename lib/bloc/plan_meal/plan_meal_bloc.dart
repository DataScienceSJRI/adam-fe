import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class MealPlanEvent {}

class FetchMealPlanEvent extends MealPlanEvent {
  final String date;
  final bool? forceRefresh;

  FetchMealPlanEvent({required this.date, this.forceRefresh =false});
}

/// STATES

abstract class MealPlanState {}

class MealPlanInitial extends MealPlanState {}

class MealPlanLoading extends MealPlanState {}

class MealPlanLoaded extends MealPlanState {
  final List<MealPlanModel> meals;

  MealPlanLoaded(this.meals);
}

class MealPlanFailure extends MealPlanState {
  final String message;

  MealPlanFailure(this.message);
}

/// BLOC

class MealPlanBloc extends Bloc<MealPlanEvent, MealPlanState> {
  final MealPlanRepository repository;

  MealPlanBloc({required this.repository}) : super(MealPlanInitial()) {
    on<FetchMealPlanEvent>((event, emit) async {
      print("🔥 FetchMealPlanEvent received: ${event.date}");

      emit(MealPlanLoading());

      try {
        final meals = await repository.fetchMealPlan(
          date: event.date,
          forceRefresh: event.forceRefresh ?? true,
        );

        print("🔥 Loaded ${meals.length} meals");

        emit(MealPlanLoaded(meals));
      } catch (e) {
        print("🔥 Error: $e");

        emit(MealPlanFailure(e.toString().replaceAll("Exception: ", "")));
      }
    });
  }
}
