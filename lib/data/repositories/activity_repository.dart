import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/activity_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityRepository {
  final ApiService _apiService = ApiService();
  final supabase = Supabase.instance.client;
  final TokenManager tokenManager = TokenManager();

  Future<void> logActivity(ActivityLogModel model) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    try {
      await _apiService.post(
        ApiEndpoints.logActivity,
        model.toJson(),
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to log activity: $e");
    }
  }

  Future<List<ActivityHistoryModel>> fetchTodayActivities(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiService.get(
        "${ApiEndpoints.getActivities}?date=$formattedDate&limit=20&offset=0",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );

      final List data = response['items'] ?? [];

      return data.map((e) => ActivityHistoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to fetch activities: $e");
    }
  }

  Future<List<String>> fetchPhysicalActivities() async {
    try {
      final response = await supabase
          .from('physical_activities')
          .select('pa_name');

      return (response as List).map((e) => e['pa_name'].toString()).toList();
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  Future<void> editActivity({
    required String activityId,
    required ActivityLogModel model,
  }) async {
    try {
      await _apiService.put(
        "${ApiEndpoints.getActivities}/$activityId",
        model.toJson(),
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to update activity: $e");
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await _apiService.delete(
        "${ApiEndpoints.getActivities}/$activityId",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to delete activity: $e");
    }
  }
}
