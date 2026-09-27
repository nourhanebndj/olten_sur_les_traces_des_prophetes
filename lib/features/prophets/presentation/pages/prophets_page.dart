import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/widgets/bottom_menu.dart';
import '../../../../data/local/database_helper.dart';
import '../../../../app/router.dart';

class ProphetsPage extends StatefulWidget {
  const ProphetsPage({super.key});

  @override
  State<ProphetsPage> createState() => _ProphetsPageState();
}

class _ProphetsPageState extends State<ProphetsPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _prophets = [];
  final Map<String, List<Map<String, dynamic>>> _quizLevelsByProphet = {};

  bool _isLoading = true;
  String? _error;

  static const Color _gold = Color(0xFFC79A3F);
  static const Color _goldLight = Color(0xFFDBB35C);

  @override
  void initState() {
    super.initState();
    _loadProphets();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _getProphetName(
    BuildContext context,
    Map<String, dynamic> prophet,
  ) {
    final isArabic =
        context.locale.languageCode == 'ar';

    if (isArabic) {
      return _readString(
        prophet,
        const [
          'nameAr',
          'name_ar',
          'nameFR',
          'name_fr',
        ],
        fallback: 'نبي',
      );
    }

    return _readString(
      prophet,
      const [
        'nameFr',
        'name_fr',
        'nameFR',
        'name_ar',
      ],
      fallback: 'Prophète',
    );
  }

  String _getProphetSummary(
    BuildContext context,
    Map<String, dynamic> prophet,
  ) {
    final isArabic =
        context.locale.languageCode == 'ar';

    if (isArabic) {
      return _readString(
        prophet,
        const [
          'summaryAr',
          'summary_ar',
          'summaryFr',
          'summary_fr',
        ],
      );
    }

    return _readString(
      prophet,
      const [
        'summaryFr',
        'summary_fr',
        'summaryAr',
        'summary_ar',
      ],
    );
  }

  String _getProphetImage(
    Map<String, dynamic> prophet,
  ) {
    return _readString(
      prophet,
      const [
        'image',
        'imagePath',
        'image_path',
      ],
    );
  }


  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadProphets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prophets =
          await _databaseHelper.getProphets();

      final Map<String, List<Map<String, dynamic>>> quizData = {};

      for (final prophet in prophets) {
        final prophetId =
            prophet['id']?.toString();

        if (prophetId == null ||
            prophetId.isEmpty) {
          continue;
        }

        try {
          final levels =
              await _databaseHelper.getQuizLevels(
            prophetId,
          );

          quizData[prophetId] = levels;
        } catch (_) {
          quizData[prophetId] = [];
        }
      }

      if (!mounted) return;

      setState(() {
        _prophets = prophets;

        _quizLevelsByProphet
          ..clear()
          ..addAll(quizData);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'prophets.errors.load'.tr();
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openProphetDetails(
    Map<String, dynamic> prophet,
  ) {
    final prophetId =
        prophet['id']?.toString();

    if (prophetId == null ||
        prophetId.isEmpty) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.prophetDetails,
      arguments: {
        'prophetId': prophetId,
      },
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Widget _buildProphetImage(
    BuildContext context,
    Map<String, dynamic> prophet, {
    double size = 90,
  }) {
    final image =
        _getProphetImage(prophet);

    if (image.isEmpty) {
      return _buildImageFallback(
        context,
        size,
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: Image.asset(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return _buildImageFallback(
            context,
            size,
          );
        },
      ),
    );
  }

  Widget _buildImageFallback(
    BuildContext context,
    double size,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(
              alpha: .72,
            ),
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.46,
        color:
            Colors.white.withValues(
          alpha: .9,
        ),
      ),
    );
  }

  // ============================================================
  // QUIZ
  // ============================================================

  Map<String, dynamic>? _getCurrentQuizLevel(
    String prophetId,
  ) {
    final levels =
        _quizLevelsByProphet[prophetId] ??
            [];

    if (levels.isEmpty) {
      return null;
    }

    Map<String, dynamic>? currentLevel;

    for (final level in levels) {
      final isCompleted =
          level['isCompleted'] == true ||
          level['completed'] == true ||
          level['is_completed'] == 1;

      if (isCompleted) {
        currentLevel = level;
      }
    }

    if (currentLevel != null) {
      return currentLevel;
    }

    for (final level in levels) {
      final isUnlocked =
          level['isUnlocked'] == true ||
          level['unlocked'] == true ||
          level['is_unlocked'] == 1;

      if (isUnlocked) {
        return level;
      }
    }

    return levels.first;
  }

  double _getQuizProgress(
    String prophetId,
  ) {
    final levels =
        _quizLevelsByProphet[prophetId] ??
            [];

    if (levels.isEmpty) {
      return 0;
    }

    int completedLevels = 0;

    for (final level in levels) {
      final isCompleted =
          level['isCompleted'] == true ||
          level['completed'] == true ||
          level['is_completed'] == 1;

      if (isCompleted) {
        completedLevels++;
      }
    }

    if (completedLevels > 0) {
      return ((completedLevels / levels.length)
              .clamp(0.0, 1.0))
          .toDouble();
    }

    final currentLevel =
        _getCurrentQuizLevel(prophetId);

    if (currentLevel == null) {
      return 0;
    }

    final bestScoreValue =
        currentLevel['bestScore'] ??
            currentLevel['best_score'] ??
            currentLevel['score'];

    if (bestScoreValue != null) {
      final score =
          double.tryParse(
        bestScoreValue.toString(),
      );

      if (score != null) {
        if (score > 1) {
          return (score / 100)
              .clamp(0.0, 1.0)
              .toDouble();
        }

        return score
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    return 0;
  }

  int _getCurrentLevelNumber(
    String prophetId,
  ) {
    final levels =
        _quizLevelsByProphet[prophetId] ??
            [];

    if (levels.isEmpty) {
      return 1;
    }

    int highestCompleted = 0;

    for (final level in levels) {
      final isCompleted =
          level['isCompleted'] == true ||
          level['completed'] == true ||
          level['is_completed'] == 1;

      if (isCompleted) {
        final value =
            level['level'] ??
                level['levelNumber'] ??
                level['level_number'];

        final number =
            int.tryParse(
          value?.toString() ?? '',
        );

        if (number != null &&
            number > highestCompleted) {
          highestCompleted = number;
        }
      }
    }

    if (highestCompleted > 0) {
      return highestCompleted;
    }

    for (final level in levels) {
      final isUnlocked =
          level['isUnlocked'] == true ||
          level['unlocked'] == true ||
          level['is_unlocked'] == 1;

      if (isUnlocked) {
        final value =
            level['level'] ??
                level['levelNumber'] ??
                level['level_number'];

        return int.tryParse(
              value?.toString() ?? '',
            ) ??
            1;
      }
    }

    return 1;
  }

  String _getProgressText(
    String prophetId,
  ) {
    final progress =
        _getQuizProgress(prophetId);

    return '${(progress * 100).round()}%';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomMenu(
        currentIndex: 1,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isArabic =
        context.locale.languageCode == 'ar';

    return Padding(
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        20,
        14,
        20,
        16,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary
                      .withValues(alpha: .72),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary
                      .withValues(alpha: .25),
                  blurRadius: 14,
                  offset:
                      const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'prophets.title'.tr(),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        colorScheme.onSurface,
                    letterSpacing: -.4,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                          const BoxDecoration(
                        color: _gold,
                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      isArabic
                          ? 'prophets.count'
                              .tr(
                              args: [
                                _prophets
                                    .length
                                    .toString(),
                              ],
                            )
                          : 'prophets.count'
                              .tr(
                              args: [
                                _prophets
                                    .length
                                    .toString(),
                              ],
                            ),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w600,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: Material(
              color:
                  colorScheme.surface,
              child: InkWell(
                onTap: _loadProphets,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color: colorScheme
                          .outlineVariant,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color:
                        colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child:
              CircularProgressIndicator(
            strokeWidth: 3,
            color:
                colorScheme.primary,
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildError(context);
    }

    if (_prophets.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      backgroundColor:
          colorScheme.surface,
      onRefresh: _loadProphets,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsetsDirectional.fromSTEB(
          18,
          4,
          18,
          25,
        ),
        itemCount: _prophets.length,
        itemBuilder:
            (context, index) {
          final prophet =
              _prophets[index];

          return _buildProphetCard(
            context,
            prophet,
            index,
          );
        },
      ),
    );
  }

  // ============================================================
  // PROPHET CARD
  // ============================================================

  Widget _buildProphetCard(
    BuildContext context,
    Map<String, dynamic> prophet,
    int index,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final name =
        _getProphetName(
      context,
      prophet,
    );

    final summary =
        _getProphetSummary(
      context,
      prophet,
    );

    final order =
        _readString(
      prophet,
      const [
        'display_order',
        'order',
      ],
      fallback:
          '${index + 1}',
    );

    final prophetId =
        prophet['id']?.toString() ?? '';

    final quizLevels =
        _quizLevelsByProphet[
                prophetId] ??
            [];

    final currentLevel =
        _getCurrentLevelNumber(
      prophetId,
    );

    final progress =
        _getQuizProgress(
      prophetId,
    );

    final progressText =
        _getProgressText(
      prophetId,
    );

    final Color primarySoft =
        colorScheme.primary.withValues(
      alpha: isDark ? .17 : .08,
    );

    final Color goldSoft =
        _gold.withValues(
      alpha: isDark ? .15 : .09,
    );

    return Container(
      margin:
          const EdgeInsetsDirectional.only(
        bottom: 13,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: isDark ? .12 : .03,
            ),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(24),
        child: InkWell(
          onTap: () =>
              _openProphetDetails(
            prophet,
          ),
          borderRadius:
              BorderRadius.circular(24),
          child: Padding(
            padding:
                const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior:
                      Clip.none,
                  children: [
                    _buildProphetImage(
                      context,
                      prophet,
                      size: 84,
                    ),

                    PositionedDirectional(
                      start: -4,
                      top: -4,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              _gold,
                              _goldLight,
                            ],
                          ),
                          shape:
                              BoxShape.circle,
                          border: Border.all(
                            color: colorScheme
                                .surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold
                                  .withValues(
                                alpha: .30,
                              ),
                              blurRadius: 6,
                              offset:
                                  const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),
                        child: Text(
                          order,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  width: 15,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight:
                              FontWeight.w900,
                          color: colorScheme
                              .onSurface,
                          letterSpacing: -.2,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        summary,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.8,
                          height: 1.5,
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              primarySoft,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .menu_book_rounded,
                              size: 13,
                              color:
                                  colorScheme
                                      .primary,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              'prophets.discover_story'
                                  .tr(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    colorScheme
                                        .primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (quizLevels
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 11,
                        ),

                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    goldSoft,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  const Icon(
                                    Icons
                                        .quiz_rounded,
                                    size: 13,
                                    color:
                                        _gold,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    'prophets.level'
                                        .tr(
                                      args: [
                                        currentLevel
                                            .toString(),
                                      ],
                                    ),
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          10.5,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                      color:
                                          _gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child: Text(
                                'prophets.progress'
                                    .tr(),
                                style:
                                    TextStyle(
                                  fontSize:
                                      10.5,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),

                            Text(
                              progressText,
                              style:
                                  TextStyle(
                                fontSize:
                                    10.5,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                color: colorScheme
                                    .primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                          child:
                              LinearProgressIndicator(
                            value:
                                progress,
                            minHeight: 6,
                            backgroundColor:
                                colorScheme
                                    .outlineVariant
                                    .withValues(
                                  alpha: .55,
                                ),
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              colorScheme
                                  .primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 6,
                ),

                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      BoxDecoration(
                    color: colorScheme
                        .primary
                        .withValues(
                      alpha:
                          isDark
                              ? .14
                              : .06,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child: Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color errorBackground =
        colorScheme.error.withValues(
      alpha: isDark ? .16 : .08,
    );

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: errorBackground,
                borderRadius:
                    BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 38,
                color:
                    colorScheme.error,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'prophets.errors.title'
                  .tr(),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
                color:
                    colorScheme.onSurface,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _error ?? '',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            SizedBox(
              height: 50,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _loadProphets,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                ),
                label: Text(
                  'common.retry'.tr(),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      colorScheme
                          .primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 24,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color background =
        _gold.withValues(
      alpha: isDark ? .15 : .09,
    );

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: background,
                borderRadius:
                    BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons
                    .auto_stories_outlined,
                size: 36,
                color: _gold,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'prophets.empty'.tr(),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}