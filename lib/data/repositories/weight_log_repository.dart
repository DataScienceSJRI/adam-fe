import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/weight_log_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:adam/service/token_manager.dart';

class WeightRepository {
  final ApiService _apiService = ApiService();
  final TokenManager tokenManager = TokenManager();

  Future<void> logWeight(WeightLogModel model) async {
    try {
      await _apiService.post(
        ApiEndpoints.postWeightLogsApi,
        model.toJson(),
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to log weight: $e");
    }
  }

  Future<List<WeightHistoryModel>> fetchWeights() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.getWeightLogsApi,
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );

      final List data = response as List;

      return data.map((e) => WeightHistoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to fetch weights: $e");
    }
  }

  Future<void> editWeight({
    required String weightId,
    required WeightLogModel model,
  }) async {
    try {
      await _apiService.patch(
        "${ApiEndpoints.getWeightLogsApi}/$weightId",
        model.toJson(),
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to update weight: $e");
    }
  }

  Future<void> deleteWeight(String weightId) async {
    try {
      await _apiService.delete(
        "${ApiEndpoints.getWeightLogsApi}/$weightId",
        headers: {
          'Authorization': 'Bearer ${await tokenManager.getValidAccessToken()}',
          'accept': 'application/json',
        },
      );
    } catch (e) {
      throw Exception("Failed to delete weight: $e");
    }
  }
}
