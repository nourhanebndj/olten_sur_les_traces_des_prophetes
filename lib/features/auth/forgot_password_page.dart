import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../auth/services/auth_service.dart';
import '../auth/widgets/olten_form_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
  });

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'forgotPassword.validation.emailRequired'.tr();
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'forgotPassword.validation.emailInvalid'.tr();
    }

    return null;
  }

  // ============================================================
  // RÉINITIALISATION
  // ============================================================

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      _showSuccessMessage();
    } on AuthException catch (e) {
      if (!mounted) return;

      final colorScheme =
          Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            e.message,
            style: TextStyle(
              color: colorScheme.onError,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final colorScheme =
          Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            '${'forgotPassword.errors.general'.tr()} $e',
            style: TextStyle(
              color: colorScheme.onError,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE SUCCÈS
  // ============================================================

  void _showSuccessMessage() {
    final colorScheme =
        Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          'forgotPassword.success'.tr(),
          style: TextStyle(
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goBack() {
    Navigator.of(context).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark =
        theme.brightness == Brightness.dark;

    final primaryTextColor =
        colorScheme.onSurface;

    final secondaryTextColor =
        colorScheme.onSurfaceVariant;

    final overlayColor = isDark
        ? Colors.black.withValues(alpha: 0.42)
        : AppColors.background.withValues(alpha: 0.55);

    final backButtonBackground = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);

    final isArabic =
        context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================

          Image.asset(
            'assets/images/auth/auth_background.png',
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.darkBackground,
                            AppColors.darkSurface,
                          ]
                        : [
                            AppColors.background,
                            AppColors.surface,
                          ],
                  ),
                ),
              );
            },
          ),

          // ======================================================
          // OVERLAY
          // ======================================================

          Container(
            color: overlayColor,
          ),

          // ======================================================
          // CONTENU
          // ======================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Column(
                        children: [
                          // ==================================================
                          // RETOUR
                          // ==================================================

                          Align(
                            alignment:
                                AlignmentDirectional.centerStart,
                            child: Container(
                              decoration: BoxDecoration(
                                color: backButtonBackground,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _goBack,
                                icon: Icon(
                                  isArabic
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_back_rounded,
                                  color: AppColors.primary,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 100),

                          // ==================================================
                          // LOGO
                          // ==================================================

                          Image.asset(
                            'assets/images/logo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 5),

                          // ==================================================
                          // TITRE
                          // ==================================================

                          Text(
                            'forgotPassword.title'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2(context).copyWith(
                              fontSize: 23,
                              color: primaryTextColor,
                            ),
                          ),

                          const SizedBox(height: 7),

                          // ==================================================
                          // SOUS-TITRE
                          // ==================================================

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                            child: Text(
                              'forgotPassword.subtitle'.tr(),
                              textAlign: TextAlign.center,
                              style:
                                  AppTextStyles.subtitle(context).copyWith(
                                fontSize: 13,
                                height: 1.4,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 55),

                          // ==================================================
                          // FORMULAIRE
                          // ==================================================

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // EMAIL
                                OltenTextField(
                                  controller: _emailController,
                                  label:
                                      'forgotPassword.fields.email'.tr(),
                                  icon:
                                      Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  textInputAction:
                                      TextInputAction.done,
                                  validator:
                                      _validateEmail,
                                  onFieldSubmitted: (_) {
                                    _handleResetPassword();
                                  },
                                ),

                                const SizedBox(height: 20),

                                // ==================================================
                                // BOUTON
                                // ==================================================

                                OltenPrimaryButton(
                                  label:
                                      'forgotPassword.buttons.reset'.tr(),
                                  isLoading: _isLoading,
                                  onPressed:
                                      _handleResetPassword,
                                ),

                                const SizedBox(height: 22),

                                // ==================================================
                                // RETOUR CONNEXION
                                // ==================================================

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isArabic
                                          ? Icons
                                              .arrow_forward_rounded
                                          : Icons
                                              .arrow_back_rounded,
                                      size: 16,
                                      color:
                                          AppColors.primary,
                                    ),

                                    const SizedBox(width: 6),

                                    GestureDetector(
                                      onTap: _goBack,
                                      child: Text(
                                        'forgotPassword.backToLogin'
                                            .tr(),
                                        style:
                                            AppTextStyles.body(
                                          context,
                                        ).copyWith(
                                          fontSize: 13,
                                          color:
                                              AppColors.primary,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}