import 'package:flutter/material.dart';

/// Palette de couleurs centralisée de l'application Olten
class AppColors {
  AppColors._();

  // =========================
  // COULEURS PRINCIPALES
  // =========================

  static const Color primary = Color(0xFF1F6B3B);
  static const Color primaryDark = Color(0xFF15492A);
  static const Color primaryLight = Color(0xFF5C8A6D);

  // =========================
  // MODE CLAIR
  // =========================

  static const Color background = Color(0xFFFBF9F4);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Colors.black54;
  static const Color textOnPrimary = Colors.white;

  static const Color divider = Color(0xFFE5E5E5);

  // =========================
  // MODE SOMBRE
  // =========================

  static const Color darkBackground = Color(0xFF101812);
  static const Color darkSurface = Color(0xFF1B261E);

  static const Color darkTextPrimary = Color(0xFFF1F5F0);
  static const Color darkTextSecondary = Color(0xFFB0BDB2);
  static const Color darkDivider = Color(0xFF344137);

  // =========================
  // GRADIENT SPLASH SCREEN
  // =========================

  static const List<Color> splashGradient = [
    Color(0xFFB7D8C7),
    Color(0xFF5C8A6D),
    Color(0xFF2F5233),
  ];
}