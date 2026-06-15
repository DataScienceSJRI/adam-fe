class MealPlanModel {
  final int pkey;
  final String userId;
  final int weekNo;
  final String date;
  final String mealType;
  final String foodName;
  final double quantity;
  final String quantityUnit;
  final double calories;
  final String planId;
  final String? recipeCode;
  final String? reaction;
  final String? comboReaction;
  final double? glValue;

  MealPlanModel({
    required this.pkey,
    required this.userId,
    required this.weekNo,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.quantity,
    required this.quantityUnit,
    required this.calories,
    required this.planId,
    this.recipeCode,
    required this.reaction,
    required this.comboReaction,
    required this.glValue,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      pkey: json['Pkey'] ?? 0,
      userId: json['user_id'] ?? '',
      weekNo: json['WeekNo'] ?? 0,
      date: json['Date'] ?? '',
      mealType: json['Timings'] ?? '',
      foodName: json['Food_Name'] ?? '',
      quantity: (json['Food_Qty'] ?? 0).toDouble(),
      quantityUnit: json['R_desc'] ?? '',
      calories: (json['Energy_kcal'] ?? 0).toDouble(),
      planId: json['plan_id'] ?? '',
      recipeCode: json['Food_Name_desc'] ?? "",
      reaction: (json['Reaction'] ?? ''),
      comboReaction: (json["Combo_Reaction"] ?? ""),
      glValue: (json['GL'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Pkey': pkey,
      'user_id': userId,
      'WeekNo': weekNo,
      'Date': date,
      'Timings': mealType,
      'Food_Name': foodName,
      'Food_Qty': quantity,
      'R_desc': quantityUnit,
      'Energy_kcal': calories,
      'plan_id': planId,
      'Food_Name_desc': recipeCode,
      'Reaction': reaction,
      'Combo_Reaction': comboReaction,
      'GL': glValue,
    };
  }

  String get imageUrl {
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
  }

  String get mealTime {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '8:00 AM';

      case 'lunch':
        return '1:00 PM';

      case 'dinner':
        return '7:00 PM';

      default:
        return '';
    }
  }
}
