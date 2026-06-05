
class ActivityLogModel {
  final int durationMin;
  final String intensity;
  final String paName;
  final String timeOfDay;

  ActivityLogModel({
    required this.durationMin,
    required this.intensity,
    required this.paName,
    required this.timeOfDay,
  });

  Map<String, dynamic> toJson() {
    return {
      "duration_min": durationMin,
      "intensity": intensity,
      "pa_name": paName,
      "time_of_day": timeOfDay,
    };
  }
}// lib/data/models/activity_history_model.dart

class ActivityHistoryModel {
  final String paName;
  final int durationMin;
  final String intensity;
  final String timeOfDay;

  ActivityHistoryModel({
    required this.paName,
    required this.durationMin,
    required this.intensity,
    required this.timeOfDay,
  });

  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryModel(
      paName: json['pa_name'] ?? '',
      durationMin: json['duration_min'] ?? 0,
      intensity: json['intensity'] ?? '',
      timeOfDay: json['time_of_day'] ?? '',
    );
  }
}