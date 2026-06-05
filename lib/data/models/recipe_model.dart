// import 'package:flutter/material.dart';
//
// class Recipe {
//   final String imageUrl;
//   final String title;
//   final String subtitle;
//   final String prepTime;
//   final String category;
//   final List<Map<String, dynamic>> tags;
//
//   Recipe({
//     required this.imageUrl,
//     required this.title,
//     required this.subtitle,
//     required this.prepTime,
//     required this.category,
//     required this.tags,
//   });
//
//   factory Recipe.fromJson(Map<String, dynamic> json) {
//     return Recipe(
//       imageUrl: json['imageUrl'] ?? '',
//       title: json['title'] ?? '',
//       subtitle: json['subtitle'] ?? '',
//       prepTime: json['prepTime'] ?? '',
//       category: json['category'] ?? 'All',
//       // Safely parse background colors if sent as hex strings, fallback to default objects
//       tags: (json['tags'] as List? ?? []).map((t) {
//         return {
//           'label': t['label'] ?? '',
//           'color': Color(int.parse(t['color'] ?? '0xFFFDF2E9')),
//           'textColor': Color(int.parse(t['textColor'] ?? '0xFF935116')),
//         };
//       }).toList(),
//     );
//   }
// }
class Recipe {
  final String recipeCode;
  final String recipeName;
  final String recipeCategory;

  Recipe({
    required this.recipeCode,
    required this.recipeName,
    required this.recipeCategory,
  });

  factory Recipe.fromJson(
      Map<String, dynamic> json,
      ) {
    return Recipe(
      recipeCode:
      json['Recipe_Code'] ?? '',

      recipeName:
      json['Recipe_Name'] ?? '',

      recipeCategory:
      json['Recipe_Category'] ?? '',
    );
  }
}