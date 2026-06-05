class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://datatools.sjri.res.in/ADAM/api/';

  static const String login = 'v1/auth/login';
  static const String logout = '${baseUrl}v1/auth/logout';
  static const String getDashboardDetails = 'v1/kpi';
  static const String getRecipes = 'v1/recipes';
  static const String searchRecipes = 'v1/recipes/search';
  static const String registerNotificationToken =
      '${baseUrl}v1/notifications/register-token';
  static const String unregisterNotificationToken =
      '${baseUrl}v1/notifications/device-token';
  static const String getProfile = 'v1/user/profile';
  static const String getPlanDaily = 'v1/plan/daily';
  static const String postDietRecall = 'v1/recall/log';
  static const String postImageRecall = 'v1/recall/image';
  static const String logActivity = 'v1/activity/log';
  static const String getActivities = 'v1/activity';
  static const String getRecall = 'v1/recall';
  static const String getReplacement = 'v1/plan/replacements';
  static const String postReplacement = 'v1/plan/replacements/request';
  static const String reaction = 'v1/plan/reaction';

}
