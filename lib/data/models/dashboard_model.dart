class DashboardModel {
  final String date;
  final double? bloodSugarControlScore;
  final NutritionModel nutrition;
  final String message;

  DashboardModel({
    required this.date,
    required this.bloodSugarControlScore,
    required this.nutrition,
    required this.message,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      date: json['date'] ?? '',
      bloodSugarControlScore:
      (json['blood_sugar_control_score'] as num?)?.toDouble(),
      nutrition: NutritionModel.fromJson(
        json['nutrition'] ?? {},
      ),
      message: json['message'] ?? '',
    );
  }
}

class NutritionModel {
  final double carbsG;
  final double proteinG;
  final double fatG;
  final double fibreG;

  NutritionModel({
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    required this.fibreG,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      fibreG: (json['fibre_g'] ?? 0).toDouble(),
    );
  }
}