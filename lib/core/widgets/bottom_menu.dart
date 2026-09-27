import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';

class BottomMenu extends StatelessWidget {
  final int currentIndex;

  const BottomMenu({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;

      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.prophets,
          (route) => false,
        );
        break;

      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.multiplayer,
          (route) => false,
        );
        break;

      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.profile,
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: isDark ? 0.35 : 0.18,
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 5),
              spreadRadius: 0,
              color: Colors.black.withValues(
                alpha: isDark ? 0.30 : 0.10,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              _onTap(context, index);
            },

            backgroundColor: Colors.transparent,

            indicatorColor: AppColors.primary.withValues(
              alpha: isDark ? 0.22 : 0.12,
            ),

            elevation: 0,

            height: 64,

            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,

            labelTextStyle:
                WidgetStateProperty.resolveWith<TextStyle?>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  );
                }

                return TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              },
            ),

            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: 26,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: const Icon(
                  Icons.home_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
                label: 'home.tabs.stories'.tr(),
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.auto_stories_outlined,
                  size: 26,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: const Icon(
                  Icons.auto_stories_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
                label: 'home.tabs.stories'.tr(),
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.sports_esports_outlined,
                  size: 26,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: const Icon(
                  Icons.sports_esports_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
                label: 'home.tabs.online'.tr(),
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.tune_outlined,
                  size: 26,
                  color: colorScheme.onSurfaceVariant,
                ),
                selectedIcon: const Icon(
                  Icons.tune_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
                label: 'home.tabs.settings'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}