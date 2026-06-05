import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/profile_model.dart';
import 'package:adam/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  final ApiService _api;

  ProfileRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ProfileModel> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    final response = await _api.get(
      ApiEndpoints.getProfile,
      headers: {'Authorization': 'Bearer $token', 'accept': 'application/json'},
    );

    return ProfileModel.fromJson(response);
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    final body = {
      "user_id": profile.userId,
      "age": profile.age,
      "gender": profile.gender,
      "weight": profile.weight,
      "height": profile.height,
      "hba1c": profile.hba1c,
      "activity_level": profile.activityLevel,
      "diet_restrictions": profile.dietRestrictions,
      "breakfast_time": profile.breakfastTime,
      "lunch_time": profile.lunchTime,
      "dinner_time": profile.dinnerTime,
    };

    final response = await _api.put(ApiEndpoints.getProfile, body,headers: {
      'Authorization':
      'Bearer $token',
      'accept':
      'application/json',
    },);
    print(
      "✅ PUT Profile ===== $response",
    );

    return true;
  }
}
