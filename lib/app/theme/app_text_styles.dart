import 'package:flutter/material.dart';

/// Styles de texte centralisés de l'application Olten
class AppTextStyles {
  AppTextStyles._();

  // =========================
  // TITRES
  // =========================

  static TextStyle h1(BuildContext context) {
    return TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }

  static TextStyle h2(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // =========================
  // SOUS-TITRES
  // =========================

  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  // =========================
  // TEXTE PRINCIPAL
  // =========================

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  // =========================
  // BOUTONS
  // =========================

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // =========================
  // LÉGENDES
  // =========================

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}