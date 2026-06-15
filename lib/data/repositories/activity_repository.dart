import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/activity_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityRepository {
  final ApiService _apiService = ApiService();
  final supabase = Supabase.instance.client;

  Future<void> logActivity(ActivityLogModel model) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    try {
      await _apiService.post(
        ApiEndpoints.logActivity,
        model.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
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
        "${ApiEndpoints.getActivities}?$formattedDate&limit=20&offset=0",
        headers: {
          'Authorization': 'Bearer $token',
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
}
