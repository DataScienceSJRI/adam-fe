import 'dart:io';

import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';

class MealPlanRepository {
  final ApiService _apiService = ApiService();
  final TokenManager tokenManager = TokenManager();

  MealPlanRepository();

  Future<List<MealPlanModel>> fetchMealPlan({
    required String date,
    bool forceRefresh = false,
  }) async {
    try {
      print("🌐 FETCHING MEAL PLAN FROM API");

      final token = await tokenManager.getValidAccessToken();

      final response = await _apiService.get(
        "${ApiEndpoints.getPlanDaily}?plan_date=$date",
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final List plans = response['meals'] ?? response;

      final meals = plans.map((e) => MealPlanModel.fromJson(e)).toList();

      return meals;
    } catch (e) {
      print("❌ ERROR ===== $e");
      throw const HttpException('The connection timed out. Please try again.');
    }
  }

  Future<dynamic> getPlanReplacement({
    required String date,
    required String day,
    required String? recipeCode,
    required String mealSlot,
    required double quantity,
  }) async {
    try {
      print("========== FETCH REPLACEMENT ==========");

      final token = await tokenManager.getValidAccessToken();

      print("🔑 TOKEN ===== $token");

      final url =
          "${ApiEndpoints.getReplacement}"
          "?date=$date"
          "&day=$day"
          "&meal_slot=$mealSlot"
          "&recipe_codes=$recipeCode"
          "&recipe_quantities=$quantity";

      print("🔗 URL ===== $url");

      final response = await _apiService.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📦 FULL RESPONSE ===== $response");

      print("📦 ALTERNATIVES ===== ${response['new_mapping']}");
      print("📦 ALTERNATIVES ===== ${response['same_category']}");


      return response;
    } catch (e) {
      print("❌ ERROR ===== $e");

      throw Exception("Failed to fetch replacement: $e");
    }
  }

  Future<dynamic> sendSwapRequest({
    required String date,
    required String mealSlot,
    required List<String> recipeCodes,
    required List<String> orignalRecipeCodes,
  }) async {
    try {
      final token = await tokenManager.getValidAccessToken();

      final body = {
        "date": date,
        "meal_slot": mealSlot,
        "recipe_codes": recipeCodes,
        "original_recipe_codes": orignalRecipeCodes,
      };

      print("📤 SWAP REQUEST BODY ===== $body");

      final response = await _apiService.post(
        ApiEndpoints.postReplacement,
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("✅ SWAP RESPONSE ===== $response");

      return response;
    } catch (e) {
      print("❌ SWAP REQUEST ERROR ===== $e");

      throw Exception("Failed to send swap request");
    }
  }

  Future<dynamic> sendMealReaction({
    required String date,
    required String mealSlot,
    required String planId,
    required String reaction,
    required List<String> recipeCodes,
  }) async {
    try {
      print("========== SEND MEAL REACTION ==========");

      final token = await tokenManager.getValidAccessToken();

      print("🔑 TOKEN ===== $token");

      final body = {
        "date": date,
        "meal_slot": mealSlot,
        "plan_id": planId,
        "reaction": reaction,
        "recipe_codes": recipeCodes,
      };

      print("📤 REACTION BODY ===== $body");

      final response = await _apiService.post(
        ApiEndpoints.reaction,
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("✅ REACTION RESPONSE ===== $response");

      return response;
    } catch (e) {
      print("❌ REACTION ERROR ===== $e");

      throw Exception("Failed to send reaction");
    }
  }

  Future<dynamic> sendRecipeMealReaction({
    required String date,
    required String mealSlot,
    required String planId,
    required String reaction,
    required String recipeCodes,
  }) async {
    try {
      print("========== SEND MEAL REACTION ==========");

      final token = await tokenManager.getValidAccessToken();

      print("🔑 TOKEN ===== $token");

      final body = {
        "date": date,
        "meal_slot": mealSlot,
        "plan_id": planId,
        "reaction": reaction,
        "recipe_code": recipeCodes,
      };

      print("📤 REACTION BODY ===== $body");

      final response = await _apiService.post(
        ApiEndpoints.reactionRecipe,
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("✅ REACTION RESPONSE ===== $response");

      return response;
    } catch (e) {
      print("❌ REACTION ERROR ===== $e");

      throw Exception("Failed to send reaction");
    }
  }

  Future<dynamic> getMealReaction({
    required String? planId,
    String? date,
    String? mealSlot,
  }) async {
    try {
      print("========== GET MEAL REACTION ==========");

      final token = await tokenManager.getValidAccessToken();

      print("🔑 TOKEN ===== $token");

      final url =
          "${ApiEndpoints.reaction}"
          "?plan_id=$planId";

      print("🔗 URL ===== $url");

      final response = await _apiService.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("✅ GET REACTION RESPONSE ===== $response");

      return response;
    } catch (e) {
      print("❌ GET REACTION ERROR ===== $e");

      throw Exception("Failed to fetch meal reaction");
    }
  }
}
