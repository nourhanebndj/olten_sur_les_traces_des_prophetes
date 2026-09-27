import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/widgets/bottom_menu.dart';
import '../../../../data/local/database_helper.dart';
import '../../../../features/auth/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isGuest = true;
  bool _isLoggingOut = false;

  int _selectedAvatar = 0;

  String _name = '';
  String _email = '';

  final List<IconData> _avatars = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.sentiment_satisfied_alt_rounded,
    Icons.auto_awesome_rounded,
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
  ];

  @override
  void initState() {
    super.initState();

    ThemeController.instance.addListener(_onThemeChanged);

    _loadProfile();
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.instance.currentUser;

      // -----------------------------------------------------------------------
      // GUEST
      // -----------------------------------------------------------------------

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _isGuest = true;
          _name = '';
          _email = '';
          _selectedAvatar = 0;
          _isLoading = false;
        });

        return;
      }

      // -----------------------------------------------------------------------
      // CONNECTED USER
      // -----------------------------------------------------------------------

      final metadata = user.userMetadata ?? {};

      final metadataName =
          metadata['full_name']?.toString() ??
          metadata['name']?.toString() ??
          '';

      final localProfile =
          await DatabaseHelper.instance.getUserProfile(
        user.id,
      );

      String name = metadataName;
      String email = user.email ?? '';
      int avatar = 0;

      if (localProfile != null) {
        final localName =
            localProfile['name']?.toString() ?? '';

        final localEmail =
            localProfile['email']?.toString() ?? '';

        if (localName.trim().isNotEmpty) {
          name = localName;
        }

        if (localEmail.trim().isNotEmpty) {
          email = localEmail;
        }

        final localAvatar = localProfile['avatar'];

        if (localAvatar is int) {
          avatar = localAvatar;
        } else {
          avatar = int.tryParse(
                localAvatar?.toString() ?? '',
              ) ??
              0;
        }
      }

      if (avatar < 0 || avatar >= _avatars.length) {
        avatar = 0;
      }

      if (!mounted) return;

      setState(() {
        _isGuest = false;
        _name = name;
        _email = email;
        _selectedAvatar = avatar;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  Future<void> _register() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.register,
    );

    if (!mounted) return;

    await _loadProfile();
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _login() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.login,
    );

    if (!mounted) return;

    await _loadProfile();
  }

  // ===========================================================================
  // CONTINUE AS GUEST
  // ===========================================================================

  void _continueAsGuest() {
    setState(() {
      _isGuest = true;
      _name = '';
      _email = '';
      _selectedAvatar = 0;
    });
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.instance.logout();

      if (!mounted) return;

      setState(() {
        _isGuest = true;
        _name = '';
        _email = '';
        _selectedAvatar = 0;
      });

      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'profile.loggedOut'.tr(),
            style: TextStyle(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showErrorMessage(e.message);
    } catch (_) {
      if (!mounted) return;

      _showErrorMessage(
        'profile.logoutError'.tr(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _showErrorMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.error,
        content: Text(
          message,
          style: TextStyle(
            color: colorScheme.onError,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // THEME
  // ===========================================================================

  Future<void> _toggleTheme(bool isDark) async {
    final newMode =
        isDark ? ThemeMode.dark : ThemeMode.light;

    try {
      await ThemeController.instance.setTheme(
        newMode,
      );
    } catch (_) {
      if (!mounted) return;

      _showErrorMessage(
        'profile.themeSaveError'.tr(),
      );
    }
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Future<void> _selectAvatar(int index) async {
    setState(() {
      _selectedAvatar = index;
    });

    Navigator.pop(context);

    final user = AuthService.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await DatabaseHelper.instance.updateUserAvatar(
        userId: user.id,
        avatar: index,
      );

      await SyncService.instance.sync();
    } catch (_) {
      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'profile.avatarSavedLocally'.tr(),
            style: TextStyle(
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // AVATAR SELECTION
  // ===========================================================================

  void _showAvatarSelection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            20,
            12,
            20,
            30,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'profile.chooseAvatar'.tr(),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'profile.customizeProfile'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatars.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final selected =
                      _selectedAvatar == index;

                  return GestureDetector(
                    onTap: () => _selectAvatar(index),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.primary
                            : colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : colorScheme.outlineVariant,
                          width: selected ? 3 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _avatars[index],
                        size: 32,
                        color: selected
                            ? colorScheme.onPrimary
                            : AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // LANGUAGE
  // ===========================================================================

  Future<void> _showLanguageSelection() async {
    final selectedLocale =
        await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme =
            Theme.of(context).colorScheme;

        final currentLanguage =
            context.locale.languageCode;

        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            20,
            12,
            20,
            30,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'profile.language.choose'.tr(),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // FRANÇAIS
              // ----------------------------------------------------------------

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(
                      context,
                      const Locale('fr'),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: currentLanguage == 'fr'
                          ? AppColors.primary.withValues(
                              alpha: 0.10,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: currentLanguage == 'fr'
                            ? AppColors.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '🇫🇷',
                          style: TextStyle(
                            fontSize: 26,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            'profile.language.french'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (currentLanguage == 'fr')
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------------------
              // ARABE
              // ----------------------------------------------------------------

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(
                      context,
                      const Locale('ar'),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: currentLanguage == 'ar'
                          ? AppColors.primary.withValues(
                              alpha: 0.10,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: currentLanguage == 'ar'
                            ? AppColors.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '🇩🇿',
                          style: TextStyle(
                            fontSize: 26,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            'profile.language.arabic'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (currentLanguage == 'ar')
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLocale == null || !mounted) {
      return;
    }

    if (selectedLocale.languageCode ==
        context.locale.languageCode) {
      return;
    }

    await context.setLocale(selectedLocale);
  }

  // ===========================================================================
  // DISPLAY NAME
  // ===========================================================================

  String get _displayName {
    if (_isGuest) {
      return 'profile.guest'.tr();
    }

    if (_name.trim().isNotEmpty) {
      return _name.trim();
    }

    return 'profile.defaultUser'.tr();
  }

  // ===========================================================================
  // PROFILE SUBTITLE
  // ===========================================================================

  String get _profileSubtitle {
    if (_isGuest) {
      return 'profile.guestProgress'.tr();
    }

    if (_email.trim().isNotEmpty) {
      return _email.trim();
    }

    return 'profile.connectedAccount'.tr();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  20,
                  16,
                  20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ---------------------------------------------------------
                    // TITLE
                    // ---------------------------------------------------------

                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(
                        start: 4,
                      ),
                      child: Text(
                        'profile.title'.tr(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------------------------------------------------------
                    // PROFILE CARD
                    // ---------------------------------------------------------

                    _buildProfileCard(),

                    const SizedBox(height: 28),

                    // ---------------------------------------------------------
                    // PREFERENCES
                    // ---------------------------------------------------------

                    _SectionLabel(
                      'profile.sections.preferences'.tr(),
                    ),

                    _SettingsGroup(
                      children: [
                        // LANGUE
                        _SettingsTile(
                          icon: Icons.translate_rounded,
                          title:
                              'profile.language.title'.tr(),
                          trailingText:
                              context.locale.languageCode == 'ar'
                                  ? 'العربية'
                                  : 'Français',
                          onTap: _showLanguageSelection,
                        ),

                        // NOTIFICATIONS
                        _SettingsTile(
                          icon:
                              Icons.notifications_none_rounded,
                          title:
                              'profile.notifications'.tr(),
                          onTap: () {},
                        ),

                        // APPARENCE
                        _SettingsTile(
                          icon: Icons.dark_mode_outlined,
                          title:
                              'profile.appearance'.tr(),
                          trailing: Switch.adaptive(
                            value: isDark,
                            onChanged: _toggleTheme,
                          ),
                          onTap: () {
                            _toggleTheme(!isDark);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ---------------------------------------------------------
                    // ABOUT
                    // ---------------------------------------------------------

                    _SectionLabel(
                      'profile.sections.about'.tr(),
                    ),

                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title:
                              'profile.aboutOlten'.tr(),
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.shield_outlined,
                          title:
                              'profile.privacy'.tr(),
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ---------------------------------------------------------
                    // VERSION
                    // ---------------------------------------------------------

                    _buildVersion(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),

      bottomNavigationBar: const BottomMenu(
        currentIndex: 3,
      ),
    );
  }

  // ===========================================================================
  // PROFILE CARD
  // ===========================================================================

  Widget _buildProfileCard() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.25,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------------
          // USER HEADER
          // ---------------------------------------------------------------

          Row(
            children: [
              GestureDetector(
                onTap: _showAvatarSelection,
                child: Stack(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.12,
                        ),
                        border: Border.all(
                          color: Colors.white38,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _avatars[_selectedAvatar],
                        size: 34,
                        color: Colors.white,
                      ),
                    ),

                    // Edit
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        width: 23,
                        height: 23,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _profileSubtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.white.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------------------
          // GUEST
          // ---------------------------------------------------------------

          if (_isGuest) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _register,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      colorScheme.surface,
                  foregroundColor:
                      AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 20,
                ),
                label: Text(
                  'profile.createAccount'.tr(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _login,
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.white.withValues(
                    alpha: 0.88,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  'profile.login'.tr(),
                ),
              ),
            ),

            const SizedBox(height: 2),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _continueAsGuest,
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.white.withValues(
                    alpha: 0.70,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(
                  'profile.continueAsGuest'.tr(),
                ),
              ),
            ),
          ]

          // ---------------------------------------------------------------
          // CONNECTED
          // ---------------------------------------------------------------

          else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    _isLoggingOut ? null : _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor:
                      Colors.white54,
                  side: const BorderSide(
                    color: Colors.white54,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isLoggingOut
                      ? 'profile.loggingOut'.tr()
                      : 'profile.logout'.tr(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // VERSION
  // ===========================================================================

  Widget _buildVersion() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          const Text(
            'OLTEN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.primaryLight,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'profile.version'.tr(),
            style: TextStyle(
              fontSize: 11,
              color:
                  colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION LABEL
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsetsDirectional.only(
        start: 8,
        bottom: 10,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color:
              colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// =============================================================================
// SETTINGS GROUP
// =============================================================================

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final items = <Widget>[];

    for (var i = 0;
        i < children.length;
        i++) {
      items.add(children[i]);

      if (i != children.length - 1) {
        items.add(
          const Divider(
            height: 1,
            thickness: 0.7,
            indent: 70,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: items,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SETTINGS TILE
// =============================================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // ICON
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // TITLE
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      colorScheme.onSurface,
                ),
              ),
            ),

            // TRAILING WIDGET
            if (trailing != null)
              trailing!

            // TRAILING TEXT
            else if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 13.5,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.primaryLight,
              ),
            ]

            // DEFAULT CHEVRON
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.primaryLight,
              ),
          ],
        ),
      ),
    );
  }
}