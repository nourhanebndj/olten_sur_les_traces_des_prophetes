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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'register.validation.nameRequired'.tr();
    }

    if (value.trim().length < 2) {
      return 'register.validation.nameShort'.tr();
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'register.validation.emailRequired'.tr();
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'register.validation.emailInvalid'.tr();
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'register.validation.passwordRequired'.tr();
    }

    if (value.length < 6) {
      return 'register.validation.passwordShort'.tr();
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'register.validation.confirmPasswordRequired'.tr();
    }

    if (value != _passwordController.text) {
      return 'register.validation.passwordMismatch'.tr();
    }

    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await AuthService.instance.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception(
          'register.errors.accountCreationFailed'.tr(),
        );
      }

      final userId = user.id;

      await DatabaseHelper.instance.saveUserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        avatar: 0,
        isGuest: false,
      );

      await DatabaseHelper.instance.ensureQuizProgressForUser(
        userId,
      );

      await DatabaseHelper.instance.claimGuestProgress(
        userId,
      );

      if (authResponse.session == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'register.snackbar.emailConfirmation'.tr(),
            ),
          ),
        );

        Navigator.of(context).pushReplacementNamed(
          AppRoutes.login,
        );

        return;
      }

      await SyncService.instance.sync();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            _authErrorMessage(e),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            '${'register.errors.registrationFailed'.tr()} $e',
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

  Future<void> _handleGoogleRegister() async {
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
            'register.snackbar.googleStarted'.tr(),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            _authErrorMessage(e),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'register.errors.googleFailed'.tr(),
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

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return 'register.errors.emailAlreadyUsed'.tr();
    }

    if (message.contains('password')) {
      return 'register.errors.passwordInvalid'.tr();
    }

    if (message.contains('email')) {
      return 'register.errors.emailInvalid'.tr();
    }

    return e.message;
  }

  void _goToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = colorScheme.surface;
    final primaryTextColor = colorScheme.onSurface;

    final secondaryTextColor =
        colorScheme.onSurfaceVariant;

    final overlayColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : AppColors.background.withValues(alpha: 0.55);

    final iconButtonBackground = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);

    final socialBackground = isDark
        ? AppColors.darkSurface
        : Colors.white;

    final isArabic =
        context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: backgroundColor,
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
                        horizontal: 18,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment:
                                AlignmentDirectional.centerStart,
                            child: Container(
                              decoration: BoxDecoration(
                                color: iconButtonBackground,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _goToLogin,
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
                          const SizedBox(height: 55),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'register.title'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2(context).copyWith(
                              fontSize: 24,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'register.subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.subtitle(context).copyWith(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 45),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                OltenTextField(
                                  controller: _nameController,
                                  label:
                                      'register.fields.fullName'.tr(),
                                  icon: Icons.person_outline,
                                  textInputAction:
                                      TextInputAction.next,
                                  validator: _validateName,
                                ),
                                const SizedBox(height: 14),
                                OltenTextField(
                                  controller: _emailController,
                                  label:
                                      'register.fields.email'.tr(),
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  textInputAction:
                                      TextInputAction.next,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                OltenTextField(
                                  controller:
                                      _passwordController,
                                  label:
                                      'register.fields.password'.tr(),
                                  icon: Icons.lock_outline,
                                  obscureText:
                                      _obscurePassword,
                                  textInputAction:
                                      TextInputAction.next,
                                  validator:
                                      _validatePassword,
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
                                const SizedBox(height: 14),
                                OltenTextField(
                                  controller:
                                      _confirmPasswordController,
                                  label:
                                      'register.fields.confirmPassword'
                                          .tr(),
                                  icon: Icons.lock_outline,
                                  obscureText:
                                      _obscureConfirmPassword,
                                  textInputAction:
                                      TextInputAction.done,
                                  validator:
                                      _validateConfirmPassword,
                                  onFieldSubmitted: (_) {
                                    _handleRegister();
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.primary,
                                      size: 21,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 22),
                                OltenPrimaryButton(
                                  label:
                                      'register.buttons.register'.tr(),
                                  isLoading: _isLoading,
                                  onPressed: _handleRegister,
                                ),
                                const SizedBox(height: 20),
                                OltenDivider(
                                  label:
                                      'register.socialDivider'.tr(),
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
                                            : _handleGoogleRegister,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  alignment:
                                      WrapAlignment.center,
                                  children: [
                                    Text(
                                      'register.loginPrompt'.tr(),
                                      style:
                                          AppTextStyles.body(context)
                                              .copyWith(
                                        fontSize: 12,
                                        color:
                                            secondaryTextColor,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _goToLogin,
                                      child: Text(
                                        'register.login'.tr(),
                                        style:
                                            AppTextStyles.body(context)
                                                .copyWith(
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
                          const SizedBox(height: 30),
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