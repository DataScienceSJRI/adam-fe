import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeRepository {
  final ApiService _apiService = ApiService();
  final TokenManager tokenManager = TokenManager();

  Future<Map<String, dynamic>> searchRecipes({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? "";

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
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString('access_token') ?? "";

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
}
