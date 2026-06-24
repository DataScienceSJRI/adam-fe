import 'package:flutter/cupertino.dart';

class PreferenceModel {
  final String id;
  final String title;
  final String? imageUrl;
  final IconData? icon;
  final String? code;

  PreferenceModel(
      {required this.id,
        required this.title,
        this.imageUrl,
        this.icon,
        this.code});
}
