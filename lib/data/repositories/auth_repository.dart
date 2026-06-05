
import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/service/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String participantId, String password) async {
    final Map<String, dynamic> body = {
      'email': participantId,
      'password': password,
    };
    final response = await _apiService.post(ApiEndpoints.login, body);

    // Assumes response contains user data or a token. Adjust accordingly.
    return response as Map<String, dynamic>;
  }
}