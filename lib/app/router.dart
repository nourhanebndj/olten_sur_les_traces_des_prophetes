import 'package:flutter/material.dart';
import 'package:olten_sur_les_traces_des_prophetes/features/multiplayer/presentation/pages/matchmaking_page.dart';
import 'package:olten_sur_les_traces_des_prophetes/features/profile/presentation/pages/profile_page.dart';

// Auth
import '../features/auth/forgot_password_page.dart';
import '../features/auth/login.dart';
import '../features/auth/register.dart';

// Onboarding
import '../features/onboarding/presentation/pages/onboarding_page.dart';

// Splash
import '../features/splash/presentation/pages/splash_page.dart';

// Home
import '../features/home/presentation/pages/home_page.dart';

// Prophets
import '../features/prophets/presentation/pages/prophets_page.dart';
import '../features/prophets/presentation/pages/prophet_detail_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';

  static const String prophets = '/prophets';
  static const String prophetDetails = '/prophet-details';
  static const String profile = '/profile';
  static const String multiplayer = '/multiplayer';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
        );

      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingPage(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );

      case AppRoutes.prophets:
        return MaterialPageRoute(
          builder: (_) => const ProphetsPage(),
        );
        case AppRoutes.profile:
          return MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          );
      case AppRoutes.multiplayer:
        return MaterialPageRoute(
          builder: (_) => const MatchmakingPage(),
        );

case AppRoutes.prophetDetails:
  final args =
      settings.arguments as Map<String, dynamic>;

  return MaterialPageRoute(
    builder: (_) => ProphetDetailPage(
      prophetId: args['prophetId'],
    ),
  );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page introuvable'),
            ),
          ),
        );
    }
  }
}