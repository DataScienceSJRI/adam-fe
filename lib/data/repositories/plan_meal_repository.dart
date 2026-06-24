import 'dart:convert';
import 'dart:io';

import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanRepository {
  final ApiService _apiService = ApiService();
  final TokenManager tokenManager = TokenManager();

  MealPlanRepository();

  // Future<List<MealPlanModel>> fetchMealPlan({required String date}) async {
  //   try {
  //     print("========== FETCH MEAL PLAN ==========");
  //
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('access_token');
  //
  //     print("🔑 TOKEN ===== $token");
  //
  //     final response = await _apiService.get(
  //       "${ApiEndpoints.getPlanDaily}?plan_date=$date",
  //       headers: {
  //         'accept': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //
  //     print("📦 RESPONSE ===== $response");
  //
  //     final List plans = response['meals'] ?? response;
  //
  //     return plans.map((e) => MealPlanModel.fromJson(e)).toList();
  //   } catch (e) {
  //     print("❌ ERROR ===== $e");
  //
  //     // Changed from FormatException to HttpException
  //     throw const HttpException('The connection timed out. Please try again.');
  //     // throw Exception("Failed to fetch meal plan: $e");
  //   }
  // }
  Future<List<MealPlanModel>> fetchMealPlan({required String date, bool forceRefresh = false,}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (date == today && !forceRefresh) {
        final savedDate = prefs.getString('meal_plan_date');
        final cachedData = prefs.getString('meal_plan_data');

        if (savedDate == today && cachedData != null) {
          print("📦 LOADING MEAL PLAN FROM CACHE");

          final List decoded = jsonDecode(cachedData);

          return decoded.map((e) => MealPlanModel.fromJson(e)).toList();
        }
      }

      print("🌐 FETCHING MEAL PLAN FROM API");

      // final token = prefs.getString('access_token');
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

      if (date == today) {
        await prefs.setString('meal_plan_date', today);

        await prefs.setString(
          'meal_plan_data',
          jsonEncode(meals.map((e) => e.toJson()).toList()),
        );

        print("💾 TODAY'S MEAL PLAN SAVED");
      }

      return meals;
    } catch (e) {
      print("❌ ERROR ===== $e");
      throw const HttpException('The connection timed out. Please try again.');
    }
  }

  Future<void> clearExpiredMealPlan() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final savedDate = prefs.getString('meal_plan_date');

    if (savedDate != today) {
      await prefs.remove('meal_plan_date');
      await prefs.remove('meal_plan_data');
    }
  }

  Future<dynamic> getPlanReplacement({
    required String date,
    required String day,
    required String? recipeCode,
    required String mealSlot,
  }) async {
    try {
      print("========== FETCH REPLACEMENT ==========");

      // final prefs = await SharedPreferences.getInstance();

      // final token = prefs.getString('access_token');
      final token = await tokenManager.getValidAccessToken();

      print("🔑 TOKEN ===== $token");

      final url =
          "${ApiEndpoints.getReplacement}"
          "?date=$date"
          "&day=$day"
          "&meal_slot=$mealSlot"
          "&recipe_codes=$recipeCode";

      print("🔗 URL ===== $url");

      final response = await _apiService.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📦 FULL RESPONSE ===== $response");

      print("📦 ALTERNATIVES ===== ${response['alternatives']}");

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
      // final prefs = await SharedPreferences.getInstance();
      //
      // final token = prefs.getString('access_token');
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

      // final prefs = await SharedPreferences.getInstance();
      //
      // final token = prefs.getString('access_token');
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

      // final prefs = await SharedPreferences.getInstance();
      //
      // final token = prefs.getString('access_token');
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

      // final prefs = await SharedPreferences.getInstance();
      //
      // final token = prefs.getString('access_token');
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
