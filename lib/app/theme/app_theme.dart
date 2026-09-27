import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thème global de l'application Olten
class AppTheme {
  AppTheme._();

  // =========================
  // THEME CLAIR
  // =========================

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      // Boutons principaux
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
      ),

      // Boutons secondaires
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),

      // Cartes
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),

      // Diviseurs
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  // =========================
  // THEME SOMBRE
  // =========================

  static ThemeData get dark {
    const Color darkBackground = Color(0xFF101812);
    const Color darkSurface = Color(0xFF1B261E);
    const Color darkText = Color(0xFFF1F5F0);
    const Color darkSecondaryText = Color(0xFFB0BDB2);
    const Color darkDivider = Color(0xFF344137);

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        surface: darkSurface,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
      ),

      // Boutons principaux
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
      ),

      // Boutons secondaires
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondaryText,
        ),
      ),

      // Cartes
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(
          color: darkSecondaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),

      // Diviseurs
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),

      // Texte global
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),

      // Icônes
      iconTheme: const IconThemeData(
        color: darkSecondaryText,
      ),
    );
  }
}