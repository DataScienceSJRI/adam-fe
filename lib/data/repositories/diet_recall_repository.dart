import 'dart:io';

import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class DietRecallRepository {
  final ApiService _apiService = ApiService();
  final supabase = Supabase.instance.client;

  Future<void> logDietRecall({
    required String mealSlot,
    required String planId,
    required bool didEatAsPlanned,
    required List<String> recipeCodes,
    required List<String> quantities,
  }) async {
    try {
      /// TOKEN
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("Access token missing");
      }

      /// DATE
      final today = DateTime.now();

      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      print("📡 DIET RECALL API ===== ${ApiEndpoints.postDietRecall}");

      /// API CALL
      final response = await _apiService.post(
        ApiEndpoints.postDietRecall,

        {
          "date": formattedDate,
          "did_eat_as_planned": didEatAsPlanned,
          "meal_slot": mealSlot.toLowerCase(),
          "plan_id": planId,
          "recipe_codes": recipeCodes,
          "actual_quantities":quantities
        },

        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      print("✅ DIET RECALL RESPONSE ===== $response");
    } catch (e) {
      print("❌ DIET RECALL ERROR ===== $e");

      rethrow;
    }
  }

  Future<void> logViaSearchChoose({
    required String recipeCode,
    required String mealSlot,
    required String quantity,
    required String planId,
    required bool didEatAsPlanned,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("Access token missing");
      }

      final today = DateTime.now();

      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      print("📡 DIET RECALL API ===== ${ApiEndpoints.postDietRecall}");

      final body = {
        "recipe_code": recipeCode,
        "date": formattedDate,
        "did_eat_as_planned": didEatAsPlanned,
        "meal_slot": mealSlot.toLowerCase(),
        "quantity": quantity,
        "plan_id": planId,
      };

      print("📦 REQUEST BODY ===== $body");

      final response = await _apiService.post(
        ApiEndpoints.postDietRecall,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      print("✅ DIET RECALL RESPONSE ===== $response");
    } catch (e) {
      print("❌ DIET RECALL ERROR ===== $e");
      rethrow;
    }
  }

  Future<String> uploadMealImage({
    required File file,
    required String mealSlot,
    required bool isPreMeal,
  }) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}";

      final path = "user/$mealSlot/${isPreMeal ? 'pre' : 'post'}_$fileName";

      await supabase.storage
          .from('meal-images')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = supabase.storage.from('meal-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

  /// =========================
  /// SAVE IMAGE RECALL API
  /// =========================
  Future<void> saveImageRecall({
    required String imageUrlPre,
    String? imageUrlPost,
    required String mealSlot,
    required String planId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("Access token missing");
      }

      final body = {
        "image_url_pre": imageUrlPre,
        "meal_slot": mealSlot,
        "plan_id": planId,
      };

      if (imageUrlPost != null) {
        body["image_url_post"] = imageUrlPost;
      }

      final response = await _apiService.post(
        ApiEndpoints.postImageRecall,

        body,

        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print("✅ IMAGE RECALL RESPONSE => $response");
    } catch (e) {
      print("❌ IMAGE RECALL ERROR => $e");
      rethrow;
    }
  }

  Future<void> logMealPlan({
    required String mealSlot,
    required String planId,
    required bool didEatAsPlanned,
    required String actualQuantity,
    required String recipeCode,
    required String date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception("Access token missing");
      }

      print("📡 DIET RECALL API ===== ${ApiEndpoints.postDietRecall}");

      final body = {
        "actual_quantity": actualQuantity,
        "date": date,
        "did_eat_as_planned": didEatAsPlanned,
        "meal_slot": mealSlot.toLowerCase(),
        "plan_id": planId,
        "recipe_code": recipeCode,
      };

      final response = await _apiService.post(
        ApiEndpoints.postDietRecall,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print("✅ DIET RECALL RESPONSE ===== $response");
    } catch (e) {
      print("❌ DIET RECALL ERROR ===== $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecall({required String date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("Access token missing. Please login again.");
      }

      final response = await _apiService.get(
        "${ApiEndpoints.getRecall}?date=$date&limit=20&offset=0",
        headers: {
          'Authorization': 'Bearer $accessToken',
          'accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      throw Exception("Failed to fetch recall: $e");
    }
  }
}
