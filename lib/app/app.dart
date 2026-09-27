import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/constants/app_constants.dart';
import '../app/theme/theme_controller.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// Widget racine de l'application Olten
class OltenApp extends StatefulWidget {
  const OltenApp({super.key});

  @override
  State<OltenApp> createState() => _OltenAppState();
}

class _OltenAppState extends State<OltenApp> {
  @override
  void initState() {
    super.initState();

    ThemeController.instance.addListener(_onThemeChanged);

    ThemeController.instance.loadTheme();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ============================================================
      // EASY LOCALIZATION
      // ============================================================
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ============================================================
      // THÈMES
      // ============================================================
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeController.instance.themeMode,

      // ============================================================
      // NAVIGATION
      // ============================================================
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}