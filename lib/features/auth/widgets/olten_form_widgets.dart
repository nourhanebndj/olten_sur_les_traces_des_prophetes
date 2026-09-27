import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Champ de formulaire personnalisé Olten.
///
/// La valeur de [label] doit être déjà traduite par la page appelante.
///
/// Exemple :
/// ```dart
/// OltenTextField(
///   controller: _emailController,
///   label: 'login.fields.email'.tr(),
///   icon: Icons.email_outlined,
/// )
/// ```
class OltenTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const OltenTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fieldTextColor = colorScheme.onSurface;
    final labelColor = colorScheme.onSurfaceVariant;

    final fillColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.58);

    final borderColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.45)
        : AppColors.primaryLight.withValues(alpha: 0.35);

    final errorColor = colorScheme.error;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,

      // Flutter gère automatiquement la direction du texte
      // selon la locale active (FR / AR).
      textDirection: Directionality.of(context),

      style: TextStyle(
        fontSize: 15,
        color: fieldTextColor,
      ),

      cursorColor: AppColors.primary,

      decoration: InputDecoration(
        labelText: label,

        labelStyle: TextStyle(
          color: labelColor,
          fontSize: 14,
        ),

        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),

        suffixIcon: suffixIcon,

        filled: true,
        fillColor: fillColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: errorColor,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),

        errorStyle: TextStyle(
          fontSize: 12,
          color: errorColor,
        ),
      ),
    );
  }
}

/// Bouton principal Olten.
///
/// Le texte [label] doit être traduit par la page appelante.
///
/// Exemple :
/// ```dart
/// OltenPrimaryButton(
///   label: 'login.buttons.login'.tr(),
///   onPressed: _login,
/// )
/// ```
class OltenPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OltenPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,

          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.55),

          disabledForegroundColor:
              AppColors.textOnPrimary.withValues(alpha: 0.85),

          minimumSize: const Size.fromHeight(52),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),

          elevation: 0,
        ),

        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }
}

/// Séparateur avec texte au centre.
///
/// Exemple :
/// ```dart
/// OltenDivider(
///   label: 'login.socialDivider'.tr(),
/// )
/// ```
class OltenDivider extends StatelessWidget {
  final String label;

  const OltenDivider({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(
              alpha: 0.8,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(
              alpha: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton de connexion sociale.
///
/// Le bouton ne contient volontairement aucun texte :
/// Google, Apple, etc. sont fournis via [icon].
class OltenSocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  const OltenSocialButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.55);

    final borderColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.45)
        : AppColors.primaryLight.withValues(alpha: 0.35);

    return SizedBox(
      width: 58,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,

          foregroundColor: colorScheme.onSurface,

          disabledForegroundColor:
              colorScheme.onSurfaceVariant.withValues(alpha: 0.5),

          side: BorderSide(
            color: borderColor,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          padding: EdgeInsets.zero,
        ),

        child: icon,
      ),
    );
  }
}