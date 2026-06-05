import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/dashboard_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardRepository {
  final ApiService _apiService = ApiService();

  Future<DashboardModel> fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    final String todayDate =
    DateFormat('yyyy-MM-dd').format(DateTime.now());

    print(
      "Fetching dashboard data for date: $todayDate with token: $token",
    );

    print(
      "API Endpoint: "
          "${ApiEndpoints.getDashboardDetails}?plan_date=$todayDate",
    );

    try {
      final response = await _apiService.get(
        "${ApiEndpoints.getDashboardDetails}?plan_date=$todayDate",
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      print("Dashboard API Response: $response");

      return DashboardModel.fromJson(response);
    } catch (e) {
      throw Exception("Failed to fetch dashboard: $e");
    }
  }
}