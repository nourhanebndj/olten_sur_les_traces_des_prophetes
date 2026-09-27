import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

/// Écran de démarrage — "Olten, sur les traces des prophètes"
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================
          // IMAGE DE FOND
          // =========================

          Image.asset(
            AppConstants.splashBackgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.splashGradient,
                  ),
                ),
              );
            },
          ),

          // =========================
          // VOILE SOMBRE
          // =========================

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  Colors.black.withValues(
                    alpha: 0.15,
                  ),
                  Colors.black.withValues(
                    alpha: 0.55,
                  ),
                ],
                stops: const [
                  0.0,
                  0.5,
                  1.0,
                ],
              ),
            ),
          ),

          // =========================
          // CONTENU
          // =========================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Column(
                children: [
                  const Spacer(
                    flex: 1,
                  ),

                  // =========================
                  // LOGO
                  // =========================

                  Image.asset(
                    AppConstants.logoAsset,
                    width: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white70,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.mosque_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      );
                    },
                  ),

                  const Spacer(
                    flex: 3,
                  ),

                  // =========================
                  // ACCROCHE
                  // =========================

                  Text(
                    'splash.learn_discover_grow'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'splash.with_their_stories'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =========================
                  // BOUTON COMMENCER
                  // =========================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.onboarding,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.start'.tr(),
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}