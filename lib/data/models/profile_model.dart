class ProfileModel {
  final String userId;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final double hba1c;
  final String activityLevel;
  final String dietRestrictions;
  final String? breakfastTime;
  final String? lunchTime;
  final String? dinnerTime;

  ProfileModel({
    required this.userId,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.hba1c,
    required this.activityLevel,
    required this.dietRestrictions,
    required this.breakfastTime,
    required this.lunchTime,
    required this.dinnerTime,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      hba1c: (json['hba1c'] ?? 0).toDouble(),
      activityLevel: json['activity_level'] ?? '',
      dietRestrictions: json['diet_restrictions'] ?? '',
      breakfastTime: json['breakfast_time'] ?? '',
      lunchTime: json['lunch_time'] ?? '',
      dinnerTime: json['dinner_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "age": age,
      "gender": gender,
      "weight": weight,
      "height": height,
      "hba1c": hba1c,
      "activity_level": activityLevel,
      "diet_restrictions": dietRestrictions,
      "breakfast_time": breakfastTime,
      "lunch_time": lunchTime,
      "dinner_time": dinnerTime,
    };
  }}
