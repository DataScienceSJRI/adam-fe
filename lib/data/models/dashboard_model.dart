class DashboardModel {
  final String date;
  final double? bloodSugarControlScore;
  final NutritionModel nutrition;
  final String message;
  final double? glycemicLoad;
  final List<dynamic> nutrientSummary;
  final Map<String, Weight> weight;
  final Map<String, MealGlModel> glByMeal;

  DashboardModel({
    required this.date,
    required this.bloodSugarControlScore,
    required this.nutrition,
    required this.message,
    required this.glycemicLoad,
    required this.nutrientSummary,
    required this.glByMeal,
    required this.weight,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final rawMealData = json['gl_by_meal'] as Map<String, dynamic>? ?? {};
    final Map<String, MealGlModel> parsedMealGl = {};
    rawMealData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedMealGl[key] = MealGlModel.fromJson(value);
      }
    });

    final rawWeightData = json['weight'] as Map<String, dynamic>? ?? {};
    final Map<String, Weight> parsedWeight = {};
    rawWeightData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedWeight[key] = Weight.fromJson(value);
      }
    });

    if (json['latest_weight'] is Map<String, dynamic> &&
        !parsedWeight.containsKey('latest_weight')) {
      parsedWeight['latest_weight'] = Weight.fromJson(
        json['latest_weight'] as Map<String, dynamic>,
      );
    }

    return DashboardModel(
      date: json['date'] ?? '',
      bloodSugarControlScore: (json['blood_sugar_control_score'] as num?)
          ?.toDouble(),
      nutrition: NutritionModel.fromJson(json['nutrition'] ?? {}),
      message: json['message'] ?? '',
      glycemicLoad: (json['gl_per_day'] as num?)?.toDouble(),
      nutrientSummary: json['nutrient_summary'] ?? [],
      glByMeal: parsedMealGl,
      weight: parsedWeight,
    );
  }

  double getRequirementFor(String nutrientName, double fallback) {
    try {
      final match = nutrientSummary.firstWhere(
        (e) => e['Nutrient'].toString().toLowerCase().contains(
          nutrientName.toLowerCase(),
        ),
      );
      if (match != null && match['Requirement'] != null) {
        return (match['Requirement'] as num).toDouble();
      }
    } catch (_) {}
    return fallback;
  }

  double getIntakeFor(String nutrientName, double fallback) {
    try {
      final match = nutrientSummary.firstWhere(
        (e) => e['Nutrient'].toString().toLowerCase().contains(
          nutrientName.toLowerCase(),
        ),
      );
      if (match != null && match['Intake'] != null) {
        return (match['Intake'] as num).toDouble();
      }
    } catch (_) {}
    return fallback;
  }
}

class MealGlModel {
  final double? planned;
  final double? actual;
  final double? weightedAvgPast14d;
  final double? yesterday;
  final String? indicator;

  MealGlModel({
    this.planned,
    this.actual,
    this.weightedAvgPast14d,
    this.yesterday,
    this.indicator,
  });

  factory MealGlModel.fromJson(Map<String, dynamic> json) {
    return MealGlModel(
      planned: (json['planned'] as num?)?.toDouble(),
      actual: (json['actual'] as num?)?.toDouble(),
      weightedAvgPast14d: (json['weighted_avg_past_14d'] as num?)?.toDouble(),
      yesterday: (json['yesterday'] as num?)?.toDouble(),
      indicator: json['indicator'] as String?,
    );
  }
}

class Weight {
  final double? weightKg;
  final String? date;
  final int? daysAgo;
  final String? source;

  Weight({this.weightKg, this.date, this.daysAgo, this.source});

  factory Weight.fromJson(Map<String, dynamic> json) {
    return Weight(
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      date: json['date'] as String?,
      daysAgo: json['days_ago'] as int?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight_kg': weightKg,
      'date': date,
      'days_ago': daysAgo,
      'source': source,
    };
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
