import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../data/local/database_helper.dart';
import '../auth/services/auth_service.dart';
import '../auth/widgets/olten_form_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'login.validation.emailRequired'.tr();
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'login.validation.emailInvalid'.tr();
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'login.validation.passwordRequired'.tr();
    }

    if (value.length < 6) {
      return 'login.validation.passwordShort'.tr();
    }

    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'login.errors.userNotFound'.tr(),
        );
      }

      final userId = user.id;
      final metadata = user.userMetadata;

      final name =
          metadata?['full_name']?.toString() ??
          metadata?['name']?.toString() ??
          '';

      await DatabaseHelper.instance.saveUserProfile(
        userId: userId,
        name: name,
        email: user.email ?? _emailController.text.trim(),
        avatar: 0,
        isGuest: false,
      );

      await DatabaseHelper.instance.claimGuestProgress(
        userId,
      );

      await DatabaseHelper.instance.ensureQuizProgressForUser(
        userId,
      );

      await SyncService.instance.sync();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            _authErrorMessage(e),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            '${'login.errors.loginFailed'.tr()} $e',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
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

  Future<void> _handleGoogleLogin() async {
    if (_isLoading || _isGoogleLoading) {
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await AuthService.instance.signInWithGoogle();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'login.snackbar.googleStarted'.tr(),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            _authErrorMessage(e),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'login.errors.googleFailed'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  String _authErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'login.errors.invalidCredentials'.tr();
    }

    if (message.contains('email not confirmed')) {
      return 'login.errors.emailNotConfirmed'.tr();
    }

    if (message.contains('too many')) {
      return 'login.errors.tooManyAttempts'.tr();
    }

    return e.message;
  }

  void _goToRegister() {
    Navigator.of(context).pushNamed(
      AppRoutes.register,
    );
  }

  void _forgotPassword() {
    Navigator.of(context).pushNamed(
      AppRoutes.forgotPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurfaceVariant;

    final overlayColor = isDark
        ? Colors.black.withValues(alpha: 0.42)
        : AppColors.background.withValues(alpha: 0.55);

    final socialBackground = isDark
        ? AppColors.darkSurface
        : Colors.white;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          Container(
            color: overlayColor,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'login.title'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2(context).copyWith(
                              fontSize: 24,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'login.subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle(context).copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 55),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                OltenTextField(
                                  controller: _emailController,
                                  label: 'login.fields.email'.tr(),
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  textInputAction:
                                      TextInputAction.next,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                OltenTextField(
                                  controller: _passwordController,
                                  label: 'login.fields.password'.tr(),
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textInputAction:
                                      TextInputAction.done,
                                  validator: _validatePassword,
                                  onFieldSubmitted: (_) {
                                    _handleLogin();
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.primary,
                                      size: 21,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor:
                                            AppColors.primary,
                                        checkColor:
                                            AppColors.textOnPrimary,
                                        side: BorderSide(
                                          color:
                                              colorScheme.outline,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe =
                                                value ?? true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'login.rememberMe'.tr(),
                                        style:
                                            AppTextStyles.caption(
                                          context,
                                        ).copyWith(
                                          fontSize: 11,
                                          color:
                                              secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          _forgotPassword,
                                      style:
                                          TextButton.styleFrom(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                      ),
                                      child: Text(
                                        'login.forgotPassword'.tr(),
                                        style:
                                            AppTextStyles.caption(
                                          context,
                                        ).copyWith(
                                          fontSize: 11,
                                          color:
                                              AppColors.primary,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                OltenPrimaryButton(
                                  label: 'login.buttons.login'.tr(),
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                                const SizedBox(height: 20),
                                OltenDivider(
                                  label: 'login.socialDivider'.tr(),
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  decoration: BoxDecoration(
                                    color: socialBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: OltenSocialButton(
                                    icon: _isGoogleLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'G',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  Color(0xFF4285F4),
                                            ),
                                          ),
                                    onPressed:
                                        _isLoading ||
                                                _isGoogleLoading
                                            ? null
                                            : _handleGoogleLogin,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  alignment:
                                      WrapAlignment.center,
                                  children: [
                                    Text(
                                      'login.registerPrompt'.tr(),
                                      style:
                                          AppTextStyles.body(
                                        context,
                                      ).copyWith(
                                        fontSize: 12,
                                        color:
                                            secondaryTextColor,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _goToRegister,
                                      child: Text(
                                        'login.register'.tr(),
                                        style:
                                            AppTextStyles.body(
                                          context,
                                        ).copyWith(
                                          fontSize: 12,
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
                          const SizedBox(height: 35),
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