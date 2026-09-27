import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/bottom_menu.dart';
import '../../../../data/local/database_helper.dart';
import '../../../../features/quiz/presentation/pages/quiz_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _carouselPage = 0;

  Map<String, dynamic>? _quizSummary;
  bool _isLoadingProgress = true;

  static const double _radiusLg = 28;
  static const double _radiusMd = 20;
  static const double _radiusPill = 999;

  static const Color _amber = Color(0xFFCB8A1E);
  static const Color _emerald = Color(0xFF3F9463);
  static const Color _plum = Color(0xFF7C64B8);
  static const Color _indigo = Color(0xFF5550B8);

  final PageController _progressController =
      PageController(
    viewportFraction: 0.90,
  );

  bool get _isArabic =>
      context.locale.languageCode == 'ar';

  IconData get _forwardIcon =>
      Icons.arrow_forward_rounded;

  IconData get _arrowIcon =>
      Icons.arrow_forward_rounded;

  @override
  void initState() {
    super.initState();
    _loadQuizProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizProgress() async {
    try {
      final progress =
          await DatabaseHelper.instance
              .getGlobalProgress();

      if (!mounted) return;

      setState(() {
        _quizSummary = progress;
        _isLoadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  void _openProphetsPage() {
    Navigator.pushNamed(
      context,
      AppRoutes.prophets,
    );
  }

  Future<void> _openQuizPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizPage(),
      ),
    );

    if (mounted) {
      await _loadQuizProgress();
    }
  }

  void _openOnlinePage() {
    Navigator.pushNamed(
      context,
      AppRoutes.multiplayer,
    );
  }

  void _openProfilePage() {
    Navigator.pushNamed(
      context,
      AppRoutes.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(),

            _buildComingSoonPage(
              icon: Icons.auto_stories_rounded,
              title: 'home.tabs.stories'.tr(),
            ),

            _buildComingSoonPage(
              icon: Icons.menu_book_rounded,
              title: 'home.tabs.quran'.tr(),
            ),

            _buildComingSoonPage(
              icon: Icons.sports_esports_rounded,
              title: 'home.tabs.online'.tr(),
            ),

            _buildComingSoonPage(
              icon: Icons.settings_rounded,
              title: 'home.tabs.settings'.tr(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentIndex,
      ),
    );
  }

  Widget _buildHomeContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth =
            constraints.maxWidth;

        final bool isSmallScreen =
            screenWidth < 360;

        final double horizontalPadding =
            isSmallScreen ? 14 : 20;

        return CustomScrollView(
          physics:
              const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  0,
                ),
                child: _buildHeader(
                  isSmallScreen,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 18),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsetsDirectional.symmetric(
                  horizontal:
                      horizontalPadding,
                ),
                child: _buildHeroCard(
                  screenWidth,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  25,
                  horizontalPadding,
                  15,
                ),
                child: _buildSectionHeader(
                  isSmallScreen,
                ),
              ),
            ),

            SliverPadding(
              padding:
                  EdgeInsetsDirectional.symmetric(
                horizontal:
                    horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildFeaturedStoryCard(
                      isSmallScreen:
                          isSmallScreen,
                      onTap:
                          _openProphetsPage,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildCompactFeatureCard(
                            imagePath:
                                'assets/images/icons/quiz.png',
                            title:
                                'home.quiz'.tr(),
                            accentColor:
                                _emerald,
                            onTap:
                                _openQuizPage,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              _buildCompactFeatureCard(
                            imagePath:
                                'assets/images/icons/defis.png',
                            title:
                                'home.challenges'.tr(),
                            accentColor:
                                _plum,
                            onTap: () {
                              setState(() {
                                _currentIndex =
                                    2;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  5,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: PageView(
                        key:
                            const PageStorageKey(
                          'home_progress_carousel',
                        ),
                        controller:
                            _progressController,
                        onPageChanged:
                            (index) {
                          setState(() {
                            _carouselPage =
                                index;
                          });
                        },
                        children: [
                          Padding(
                            padding:
                                const EdgeInsetsDirectional
                                    .only(
                              end: 6,
                            ),
                            child:
                                _buildOnlineCard(
                              screenWidth,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsetsDirectional
                                    .only(
                              start: 6,
                            ),
                            child:
                                _buildProgressCard(
                              screenWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCarouselDots(2),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  25,
                ),
                child: _buildQuoteCard(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    bool isSmallScreen,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
        SizedBox(
          width: isSmallScreen ? 7 : 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Olten',
                style:
                    AppTextStyles.h2(context)
                        .copyWith(
                  color:
                      colorScheme.primary,
                  fontSize:
                      isSmallScreen
                          ? 22
                          : 25,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _isArabic
                    ? 'على خطى الأنبياء'
                    : 'Sur les traces des prophètes',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppTextStyles.caption(
                  context,
                ).copyWith(
                  fontSize:
                      isSmallScreen
                          ? 9.5
                          : 11,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _openProfilePage,
            customBorder:
                const CircleBorder(),
            child: Container(
              width:
                  isSmallScreen ? 46 : 50,
              height:
                  isSmallScreen ? 46 : 50,
              decoration:
                  BoxDecoration(
                color: colorScheme
                    .surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color:
                    colorScheme.onSurface,
                size:
                    isSmallScreen ? 27 : 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    bool isSmallScreen,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'home.discover_learn'.tr(),
            style:
                AppTextStyles.h2(context)
                    .copyWith(
              fontSize:
                  isSmallScreen ? 19 : 22,
            ),
          ),
        ),
        TextButton(
          onPressed: _openProphetsPage,
          style:
              TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 3,
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                'home.see_all'.tr(),
                style: TextStyle(
                  color:
                      colorScheme.primary,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                _forwardIcon,
                color:
                    colorScheme.primary,
                size: 25,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    double screenWidth,
  ) {
    final bool small =
        screenWidth < 360;

    return Container(
      width: double.infinity,
      height: small ? 190 : 210,
      clipBehavior: Clip.antiAlias,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          _radiusLg,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/accueil_image.png',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration:
                BoxDecoration(
              gradient:
                  LinearGradient(
                begin:
                    AlignmentDirectional
                        .centerStart,
                end:
                    AlignmentDirectional
                        .centerEnd,
                colors: [
                  Color(0xE6002948),
                  Color(0xB0004168),
                  Color(0x35004168),
                  Colors.transparent,
                ],
                stops: [
                  0.0,
                  0.35,
                  0.65,
                  1.0,
                ],
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.all(
              small ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'home.greeting'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        small ? 23 : 26,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width:
                      small ? 230 : 270,
                  child: Text(
                    'home.hero_description'
                        .tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          small ? 13 : 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 46,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _openProphetsPage,
                    icon: const Icon(
                      Icons
                          .menu_book_rounded,
                      size: 22,
                    ),
                    label: Text(
                      'common.start'.tr(),
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFFFD45C,
                      ),
                      foregroundColor:
                          const Color(
                        0xFF092B45,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 21,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          _radiusPill,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStoryCard({
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    final theme =
        Theme.of(context);

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color cardColor = isDark
        ? AppColors.darkSurface
        : const Color(0xFFFBF6EC);

    final Color borderColor = isDark
        ? AppColors.darkDivider
        : Colors.black.withValues(
            alpha: 0.08,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          _radiusLg,
        ),
        child: Ink(
          decoration:
              BoxDecoration(
            color: cardColor,
            borderRadius:
                BorderRadius.circular(
              _radiusLg,
            ),
            border:
                Border.all(
              color: borderColor,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 16,
                  offset:
                      const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsetsDirectional
                    .fromSTEB(
              20,
              18,
              14,
              18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.stories'.tr(),
                        style:
                            AppTextStyles.h2(
                          context,
                        ).copyWith(
                          fontSize:
                              isSmallScreen
                                  ? 19
                                  : 21,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'home.stories_description'
                            .tr(),
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            AppTextStyles.body(
                          context,
                        ).copyWith(
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              _amber.withValues(
                            alpha:
                                isDark
                                    ? 0.20
                                    : 0.14,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            _radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              'common.start'
                                  .tr(),
                              style:
                                  const TextStyle(
                                color:
                                    _amber,
                                fontSize:
                                    12.5,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const SizedBox(
                                width: 4),
                            Icon(
                              _arrowIcon,
                              color:
                                  _amber,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/icons/histoire.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFeatureCard({
    required String imagePath,
    required String title,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color cardColor = isDark
        ? AppColors.darkSurface
        : const Color(0xFFFBF6EC);

    final Color borderColor = isDark
        ? AppColors.darkDivider
        : Colors.black.withValues(
            alpha: 0.08,
          );

    return AspectRatio(
      aspectRatio: 0.86,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(
            _radiusMd,
          ),
          child: Ink(
            decoration:
                BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.circular(
                _radiusMd,
              ),
              border:
                  Border.all(
                color: borderColor,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    padding:
                        const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(
                      color:
                          accentColor.withValues(
                        alpha:
                            isDark ? 0.20 : 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment:
                        AlignmentDirectional
                            .centerEnd,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration:
                          BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _forwardIcon,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    double screenWidth,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color cardColor = isDark
        ? AppColors.darkSurface
        : const Color(0xFFFBF6EC);

    final Color borderColor = isDark
        ? AppColors.darkDivider
        : Colors.black.withValues(
            alpha: 0.08,
          );

    final progress =
        _quizSummary ?? {};

    final int completedLevels =
        (progress['completedLevels']
                as num?)
            ?.toInt() ??
        0;

    final int totalLevels =
        (progress['levels'] as num?)
            ?.toInt() ??
        0;

    final double progressValue =
        totalLevels > 0
            ? (completedLevels /
                    totalLevels)
                .clamp(0.0, 1.0)
            : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          _radiusMd,
        ),
        onTap: _openQuizPage,
        child: Ink(
          padding:
              const EdgeInsets.all(20),
          decoration:
              BoxDecoration(
            color: cardColor,
            border:
                Border.all(
              color: borderColor,
            ),
            borderRadius:
                BorderRadius.circular(
              _radiusMd,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        BoxDecoration(
                      color:
                          _emerald.withValues(
                        alpha:
                            isDark ? 0.20 : 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.bar_chart_rounded,
                      color: _emerald,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home.progress'.tr(),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                colorScheme
                                    .onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'home.continue_learning'
                              .tr(),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              AppTextStyles
                                  .caption(
                            context,
                          ).copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _forwardIcon,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    size: 26,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      child:
                          LinearProgressIndicator(
                        value:
                            _isLoadingProgress
                                ? 0
                                : progressValue,
                        minHeight: 9,
                        backgroundColor:
                            colorScheme
                                .onSurface
                                .withValues(
                          alpha: 0.08,
                        ),
                        valueColor:
                            const AlwaysStoppedAnimation<
                                Color>(
                          _emerald,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isLoadingProgress
                        ? '...'
                        : '$completedLevels/$totalLevels',
                    style:
                        const TextStyle(
                      color: _emerald,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineCard(
    double screenWidth,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color cardColor = isDark
        ? AppColors.darkSurface
        : const Color(0xFFFBF6EC);

    final Color borderColor = isDark
        ? AppColors.darkDivider
        : Colors.black.withValues(
            alpha: 0.08,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          _radiusMd,
        ),
        onTap: _openOnlinePage,
        child: Ink(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            color: cardColor,
            border:
                Border.all(
              color: borderColor,
            ),
            borderRadius:
                BorderRadius.circular(
              _radiusMd,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      _indigo.withValues(
                    alpha:
                        isDark ? 0.20 : 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.sports_esports_rounded,
                  color: _indigo,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.play_online'.tr(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              const BoxDecoration(
                            color: _emerald,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'home.online'.tr(),
                          style:
                              const TextStyle(
                            color: _emerald,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home.online_description'
                          .tr(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppTextStyles.caption(
                        context,
                      ).copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _forwardIcon,
                color:
                    colorScheme
                        .onSurfaceVariant,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDots(
    int count,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children:
          List.generate(
        count,
        (index) {
          final bool isActive =
              index == _carouselPage;

          return AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
            margin:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            width:
                isActive ? 20 : 7,
            height: 7,
            decoration:
                BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.primary
                      .withValues(
                    alpha: 0.25,
                  ),
              borderRadius:
                  BorderRadius.circular(
                _radiusPill,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          _radiusLg,
        ),
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F6B3B),
            Color(0xFF15492A),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          _radiusLg,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter:
                    _StarPatternPainter(
                  color:
                      Colors.white.withValues(
                    alpha: 0.055,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'home.quote'.tr(),
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'home.quote_reference'
                        .tr(),
                    style:
                        TextStyle(
                      color:
                          Colors.white.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 95,
            height: 95,
            decoration:
                BoxDecoration(
              color:
                  colorScheme.primary
                      .withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color:
                  colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style:
                AppTextStyles.h2(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              'home.coming_soon'.tr(),
              textAlign:
                  TextAlign.center,
              style:
                  AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPatternPainter
    extends CustomPainter {
  final Color color;

  const _StarPatternPainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const double cell = 36;

    final int cols =
        (size.width / cell).ceil() + 1;

    final int rows =
        (size.height / cell).ceil() + 1;

    for (int row = 0;
        row < rows;
        row++) {
      for (int col = 0;
          col < cols;
          col++) {
        final Offset center = Offset(
          col * cell,
          row * cell,
        );

        _drawEightPointStar(
          canvas,
          paint,
          center,
          cell * 0.42,
        );
      }
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
  ) {
    final Path squareA = Path();
    final Path squareB = Path();

    for (int i = 0; i < 4; i++) {
      final double angleA =
          (pi / 2) * i;

      final double angleB =
          (pi / 2) * i + pi / 4;

      final Offset pointA = Offset(
        center.dx +
            radius * cos(angleA),
        center.dy +
            radius * sin(angleA),
      );

      final Offset pointB = Offset(
        center.dx +
            radius * cos(angleB),
        center.dy +
            radius * sin(angleB),
      );

      if (i == 0) {
        squareA.moveTo(
          pointA.dx,
          pointA.dy,
        );

        squareB.moveTo(
          pointB.dx,
          pointB.dy,
        );
      } else {
        squareA.lineTo(
          pointA.dx,
          pointA.dy,
        );

        squareB.lineTo(
          pointB.dx,
          pointB.dy,
        );
      }
    }

    squareA.close();
    squareB.close();

    canvas.drawPath(
      squareA,
      paint,
    );

    canvas.drawPath(
      squareB,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _StarPatternPainter
        oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}