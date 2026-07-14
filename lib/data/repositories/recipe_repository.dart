import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeRepository {
  final ApiService _apiService = ApiService();
  final TokenManager tokenManager = TokenManager();

  Future<Map<String, dynamic>> searchRecipes({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final response = await _apiService.get(
      "${ApiEndpoints.searchRecipes}?q=$query&page=$page&page_size=$pageSize",
      headers: {
        "accept": "application/json",
        "Authorization": "Bearer ${await tokenManager.getValidAccessToken()}",
      },
    );

    return response;
  }

  Future<Map<String, dynamic>> searchLogRecipes({required String query}) async {
    final response = await _apiService.get(
      "${ApiEndpoints.searchRecipes}?q=$query",
      headers: {
        "accept": "application/json",
        "Authorization": "Bearer ${await tokenManager.getValidAccessToken()}",
      },
    );

    return response;
  }

  Future<Map<String, dynamic>> fetchRecipes({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("Access token missing. Please login again.");
      }

      final response = await _apiService.get(
        "${ApiEndpoints.getRecipes}?page=$page&page_size=$pageSize",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      throw Exception("Failed to fetch recipes: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchIngredients(String recipeCode) async {
    final response = await Supabase.instance.client
        .from('Recipes_ingredient')
        .select('Ingredients, Ing_raw_amounts_g, Unit')
        .eq('Recipe_Code', recipeCode);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> likeRecipe(String recipeCode) async {
    final body = {"Recipe_Code": recipeCode};
    try {
      final response = await _apiService.post(
        "${ApiEndpoints.getRecipes}/$recipeCode/like",
        body,
        headers: {
          "Authorization": "Bearer ${await tokenManager.getValidAccessToken()}",
          'accept': 'application/json',
        },
      );
      return response;
    } catch (e) {
      throw Exception("Failed to like recipe: $e");
    }
  }

  Future<Map<String, dynamic>> dislikeRecipe(String recipeCode) async {
    final body = {"Recipe_Code": recipeCode};
    try {
      final response = await _apiService.post(
        "${ApiEndpoints.getRecipes}/$recipeCode/dislike",
        body,
        headers: {
          "Authorization": "Bearer ${await tokenManager.getValidAccessToken()}",
          'accept': 'application/json',
        },
      );
      return response;
    } catch (e) {
      throw Exception("Failed to like recipe: $e");
    }
  }

  Future<Map<String, dynamic>> fetchLikedRecipes() async {
    try {
      final response = await _apiService.get(
        "${ApiEndpoints.getRecipes}/like",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      throw Exception("Failed to fetch liked recipes: $e");
    }
  }

  Future<Map<String, dynamic>> fetchDislikedRecipes() async {
    try {
      final response = await _apiService.get(
        "${ApiEndpoints.getRecipes}/dislike",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      throw Exception("Failed to fetch disliked recipes: $e");
    }
  }
}
