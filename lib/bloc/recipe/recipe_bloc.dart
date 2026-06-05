import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// =========================
/// EVENTS
/// =========================
abstract class RecipeEvent {}

class LoadRecipesRequested extends RecipeEvent {}

class LoadMoreRecipesRequested extends RecipeEvent {}

class RefreshRecipesRequested extends RecipeEvent {}

/// =========================
/// STATES
/// =========================
abstract class RecipeState {}

class RecipeLoading extends RecipeState {}

class RecipeLoaded extends RecipeState {
  final List<Recipe> recipes;
  final int page;
  final bool hasNext;
  final bool isLoadingMore;

  RecipeLoaded({
    required this.recipes,
    required this.page,
    required this.hasNext,
    required this.isLoadingMore,
  });

  RecipeLoaded copyWith({
    List<Recipe>? recipes,
    int? page,
    bool? hasNext,
    bool? isLoadingMore,
  }) {
    return RecipeLoaded(
      recipes: recipes ?? this.recipes,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class RecipeError extends RecipeState {
  final String message;
  RecipeError(this.message);
}

/// =========================
/// BLOC
/// =========================
class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final RecipeRepository repository;

  RecipeBloc(this.repository) : super(RecipeLoading()) {
    on<LoadRecipesRequested>(_onLoad);
    on<LoadMoreRecipesRequested>(_onLoadMore);
  }

  // 🔥 FIRST PAGE
  Future<void> _onLoad(
      LoadRecipesRequested event,
      Emitter<RecipeState> emit,
      ) async {
    emit(RecipeLoading());

    try {
      final response = await repository.fetchRecipes(
        page: 1,
        pageSize: 20,
      );

      final recipes = (response['recipes'] as List)
          .map((e) => Recipe.fromJson(e))
          .toList();

      emit(RecipeLoaded(
        recipes: recipes,
        page: 2,
        hasNext: response['has_next'] ?? false,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  // 🔥 NEXT PAGE (IMPORTANT PART)
  Future<void> _onLoadMore(
      LoadMoreRecipesRequested event,
      Emitter<RecipeState> emit,
      ) async {
    final current = state;

    if (current is! RecipeLoaded) return;
    if (!current.hasNext || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final response = await repository.fetchRecipes(
        page: current.page,
        pageSize: 20,
      );

      final newRecipes = (response['recipes'] as List)
          .map((e) => Recipe.fromJson(e))
          .toList();

      emit(current.copyWith(
        recipes: [...current.recipes, ...newRecipes],
        page: current.page + 1,
        hasNext: response['has_next'] ?? false,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

}