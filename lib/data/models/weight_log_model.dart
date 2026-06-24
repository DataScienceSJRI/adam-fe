class WeightLogModel {
  final double weight;
  final String date;

  WeightLogModel({
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      "weight_kg": weight,
      "date": date,
    };
  }
}

class WeightHistoryModel {
  final String id;
  final double weight;
  final String date;

  WeightHistoryModel({
    required this.id,
    required this.weight,
    required this.date,
  });

  factory WeightHistoryModel.fromJson(Map<String, dynamic> json) {
    return WeightHistoryModel(
      id: json["id"] ?? "",
      weight: (json["weight_kg"] ?? 0).toDouble(),
      date: json["date"] ?? "",
    );
  }
}