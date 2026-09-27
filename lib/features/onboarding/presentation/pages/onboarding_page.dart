import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Un slide d'onboarding
class _OnboardingSlide {
  final String gifAsset;
  final String titleKey;
  final String subtitleKey;
  final String descriptionKey;

  const _OnboardingSlide({
    required this.gifAsset,
    required this.titleKey,
    required this.subtitleKey,
    required this.descriptionKey,
  });
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    gifAsset: 'assets/animations/quran.png',
    titleKey: 'onboarding.slides.stories.title',
    subtitleKey: 'onboarding.slides.stories.subtitle',
    descriptionKey: 'onboarding.slides.stories.description',
  ),
  _OnboardingSlide(
    gifAsset: 'assets/animations/quiz.png',
    titleKey: 'onboarding.slides.quiz.title',
    subtitleKey: 'onboarding.slides.quiz.subtitle',
    descriptionKey: 'onboarding.slides.quiz.description',
  ),
  _OnboardingSlide(
    gifAsset: 'assets/animations/audio.png',
    titleKey: 'onboarding.slides.offline.title',
    subtitleKey: 'onboarding.slides.offline.subtitle',
    descriptionKey: 'onboarding.slides.offline.description',
  ),
];

/// Écran d'introduction de l'application Olten.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _finishOnboarding();
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.home,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;
    final bool isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // =========================
                        // ILLUSTRATION
                        // =========================

                        SizedBox(
                          width: 300,
                          height: 300,
                          child: Image.asset(
                            slide.gifAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.15 : 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 72,
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.6 : 0.4,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // =========================
                        // TITRE
                        // =========================

                        Text(
                          slide.titleKey.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2(context),
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // SOUS-TITRE
                        // =========================

                        Text(
                          slide.subtitleKey.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle(context),
                        ),

                        const SizedBox(height: 18),

                        // =========================
                        // DESCRIPTION
                        // =========================

                        Text(
                          slide.descriptionKey.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // =========================
            // INDICATEURS
            // =========================

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) {
                  final bool isActive = _currentPage == index;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPage(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 250,
                        ),
                        width: isActive ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(
                                  alpha: isDark ? 0.30 : 0.25,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // BOUTON PRINCIPAL
            // =========================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _goNext,
                  child: Text(
                    isLast
                        ? 'onboarding.start'.tr()
                        : 'onboarding.next'.tr(),
                    style: AppTextStyles.button.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // =========================
            // PASSER
            // =========================

            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'onboarding.skip'.tr(),
                style: AppTextStyles.caption(context),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}