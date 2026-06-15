import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class AppSnackBar {
  AppSnackBar._();

  static void show(
      BuildContext context, {
        required String message,
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 2),
      }) {
    IconData icon;
    Color backgroundColor;

    switch (type) {
      case SnackBarType.success:
        icon = Icons.check_circle;
        backgroundColor = const Color(0xFF007A50);
        break;

      case SnackBarType.error:
        icon = Icons.error_outline;
        backgroundColor = const Color(0xFFD32F2F);
        break;

      case SnackBarType.warning:
        icon = Icons.warning_amber_rounded;
        backgroundColor = const Color(0xFFF57C00);
        break;

      case SnackBarType.info:
        icon = Icons.info_outline;
        backgroundColor = const Color(0xFF1976D2);
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: duration,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}