import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // The Exact Figma Premium Colors
  static const Color primaryGreen = Color(0xFF0F5132);    // Deep Forest Green for text/targets
  static const Color accentGreen = Color(0xFF10B981);     // Vibrant Electric Mint/Emerald for buttons/active states
  static const Color navDarkBackground = Color(0xFF0F172A); // Saturated Navy/Slate (Tailwind Gray 900)
  static const Color backgroundLight = Color(0xFFF9FAFB);  // Soft off-white canvas gray
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textDark = Color(0xFF111827);        // Rich near-black for headings
  static const Color textLight = Color(0xFF6B7280);       // Soft muted gray for secondary descriptions
  static const Color borderLight = Color(0xFFE5E7EB);     // Subtle crisp card borders

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: cardBackground,
        background: backgroundLight,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textLight),
      ),
    );
  }
}