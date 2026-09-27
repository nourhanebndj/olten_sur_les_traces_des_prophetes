import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/bottom_menu.dart';
import '../../../../data/local/database_helper.dart';
import '../widgets/quiz_level_card.dart';
import 'quiz_play_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final DatabaseHelper _database = DatabaseHelper.instance;

  List<Map<String, dynamic>> _prophets = [];
  bool _loading = true;

  static const Color _primary = Color(0xFF2F7A5B);
  static const Color _primaryDark = Color(0xFF1F5B41);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
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
          'nameFr',
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
        'nameAr',
        'name_ar',
      ],
      fallback: 'Prophète',
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

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      await _database.initializeProphetStories();
      await _database.initializeQuizzes();

      final prophets =
          await _database.getProphets();

      if (!mounted) return;

      setState(() {
        _prophets = prophets;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openLevel(
    String prophetId,
    int level,
  ) async {
    final unlocked =
        await _database.isQuizLevelUnlocked(
      prophetId,
      level,
    );

    if (!unlocked) {
      if (!mounted) return;

      final colorScheme =
          Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            backgroundColor:
                colorScheme.inverseSurface,
            margin:
                const EdgeInsetsDirectional
                    .fromSTEB(
              18,
              0,
              18,
              18,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color:
                      colorScheme
                          .onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'quiz.locked_message'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          colorScheme
                              .onInverseSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPlayPage(
          prophetId: prophetId,
          level: level,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

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
            _buildHeader(),
            Expanded(
              child: _buildBody(),
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

  Widget _buildHeader() {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Padding(
      padding:
          const EdgeInsetsDirectional
              .fromSTEB(
        20,
        15,
        20,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    AlignmentDirectional
                        .topStart,
                end:
                    AlignmentDirectional
                        .bottomEnd,
                colors: [
                  _primary,
                  _primaryDark,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color:
                      _primary.withValues(
                    alpha:
                        isDark ? .16 : .20,
                  ),
                  blurRadius: 14,
                  offset:
                      const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.title'.tr(),
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        colorScheme.onSurface,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'quiz.prophets_count'.tr(
                    args: [
                      _prophets.length
                          .toString(),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w600,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: colorScheme
                .surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(15),
            child: InkWell(
              onTap: _loadData,
              borderRadius:
                  BorderRadius.circular(15),
              child: Container(
                width: 45,
                height: 45,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color: colorScheme
                        .outlineVariant,
                  ),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: _primary,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme =
        Theme.of(context).colorScheme;

    if (_loading) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child:
              CircularProgressIndicator(
            strokeWidth: 3,
            color:
                colorScheme.primary,
          ),
        ),
      );
    }

    if (_prophets.isEmpty) {
      return RefreshIndicator(
        color:
            colorScheme.primary,
        backgroundColor:
            colorScheme.surface,
        onRefresh: _loadData,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            Center(
              child: Text(
                'quiz.empty_prophets'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:
          colorScheme.primary,
      backgroundColor:
          colorScheme.surface,
      onRefresh: _loadData,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsetsDirectional
                .fromSTEB(
          18,
          4,
          18,
          30,
        ),
        itemCount:
            _prophets.length,
        itemBuilder:
            (context, index) {
          final prophet =
              _prophets[index];

          final prophetId =
              prophet['id']?.toString() ??
                  '';

          return _ProphetQuizCard(
            key:
                ValueKey(prophetId),
            prophetId:
                prophetId,
            prophetName:
                _getProphetName(
              context,
              prophet,
            ),
            prophetImage:
                _getProphetImage(
              prophet,
            ),
            database:
                _database,
            onOpenLevel:
                _openLevel,
          );
        },
      ),
    );
  }
}

class _ProphetQuizCard
    extends StatefulWidget {
  final String prophetId;
  final String prophetName;
  final String prophetImage;
  final DatabaseHelper database;

  final Future<void> Function(
    String prophetId,
    int level,
  ) onOpenLevel;

  const _ProphetQuizCard({
    super.key,
    required this.prophetId,
    required this.prophetName,
    required this.prophetImage,
    required this.database,
    required this.onOpenLevel,
  });

  @override
  State<_ProphetQuizCard> createState() =>
      _ProphetQuizCardState();
}

class _ProphetQuizCardState
    extends State<_ProphetQuizCard> {
  List<Map<String, dynamic>> _levels =
      [];

  bool _loading = true;

  static const Color _primary =
      Color(0xFF2F7A5B);

  static const Color _primaryDark =
      Color(0xFF1F5B41);

  static const Color _primarySoft =
      Color(0xFFEAF5EE);

  static const Color _gold =
      Color(0xFFC79A3F);

  static const Color _goldSoft =
      Color(0xFFFBF2E0);

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final levels =
          await widget.database
              .getQuizLevels(
        widget.prophetId,
      );

      if (!mounted) return;

      setState(() {
        _levels = levels;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _levels = [];
        _loading = false;
      });
    }
  }

  Widget _buildProphetImage() {
    if (widget.prophetImage.isEmpty) {
      return _buildFallbackImage();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),
      child: Image.asset(
        widget.prophetImage,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return _buildFallbackImage();
        },
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              AlignmentDirectional
                  .topStart,
          end:
              AlignmentDirectional
                  .bottomEnd,
          colors: [
            _primary,
            _primaryDark,
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  int _completedLevels() {
    return _levels.where((level) {
      final total = _readInt(
        level,
        const [
          'total_questions',
          'totalQuestions',
        ],
      );

      final best = _readInt(
        level,
        const [
          'best_score',
          'bestScore',
        ],
      );

      final completed = _readBool(
        level,
        const [
          'completed',
          'isCompleted',
          'is_completed',
        ],
      );

      return total > 0 &&
          best == total &&
          completed;
    }).length;
  }

  int _unlockedLevels() {
    return _levels.where((level) {
      return _readBool(
        level,
        const [
          'unlocked',
          'isUnlocked',
          'is_unlocked',
        ],
      );
    }).length;
  }

  double _progress() {
    if (_levels.isEmpty) {
      return 0;
    }

    return (_completedLevels() /
            _levels.length)
        .clamp(0.0, 1.0);
  }

  int _readInt(
    Map<String, dynamic> data,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      final parsed = int.tryParse(
        value?.toString() ?? '',
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return fallback;
  }

  bool _readBool(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value == true || value == 1) {
        return true;
      }

      if (value is String) {
        final normalized =
            value.toLowerCase().trim();

        if (normalized == 'true' ||
            normalized == '1') {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final completed =
        _completedLevels();

    final totalLevels =
        _levels.length;

    final unlocked =
        _unlockedLevels();

    final progress =
        _progress();

    return Container(
      margin:
          const EdgeInsetsDirectional.only(
        bottom: 17,
      ),
      decoration: BoxDecoration(
        color:
            colorScheme.surface,
        borderRadius:
            BorderRadius.circular(27),
        border: Border.all(
          color:
              colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color:
                colorScheme.shadow.withValues(
              alpha:
                  isDark ? .18 : .045,
            ),
            blurRadius: 22,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(27),
        child: Column(
          children: [
            _buildTopSection(
              completed,
              totalLevels,
              unlocked,
              progress,
            ),
            if (_loading)
              Padding(
                padding:
                    const EdgeInsetsDirectional
                        .symmetric(
                  vertical: 25,
                ),
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color:
                        colorScheme.primary,
                  ),
                ),
              )
            else if (_levels.isEmpty)
              Padding(
                padding:
                    const EdgeInsetsDirectional
                        .fromSTEB(
                  18,
                  5,
                  18,
                  20,
                ),
                child: Align(
                  alignment:
                      AlignmentDirectional
                          .centerStart,
                  child: Text(
                    'quiz.no_quiz_for_prophet'
                        .tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              _buildLevels(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
    int completed,
    int totalLevels,
    int unlocked,
    double progress,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final primarySoft = isDark
        ? AppColors.primary.withValues(
            alpha: .15,
          )
        : _primarySoft;

    final goldSoft = isDark
        ? _gold.withValues(
            alpha: .14,
          )
        : _goldSoft;

    return Container(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  _buildProphetImage(),

                  PositionedDirectional(
                    end: -6,
                    bottom: -6,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration:
                          BoxDecoration(
                        color: _gold,
                        shape:
                            BoxShape.circle,
                        border: Border.all(
                          color:
                              scheme.surface,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold
                                .withValues(
                              alpha: .25,
                            ),
                            blurRadius: 7,
                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      child:
                          const Icon(
                        Icons.quiz_rounded,
                        color:
                            Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.prophetName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            scheme.onSurface,
                        letterSpacing: -.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsetsDirectional
                                  .fromSTEB(
                            9,
                            5,
                            9,
                            5,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                primarySoft,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .layers_rounded,
                                size: 13,
                                color:
                                    scheme
                                        .primary,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                totalLevels == 0
                                    ? 'quiz.title'
                                        .tr()
                                    : 'quiz.levels_count'
                                        .tr(
                                        args: [
                                          totalLevels
                                              .toString(),
                                        ],
                                      ),
                                style: TextStyle(
                                  fontSize:
                                      10.5,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      scheme
                                          .primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unlocked > 0) ...[
                          const SizedBox(
                            width: 7,
                          ),
                          Container(
                            padding:
                                const EdgeInsetsDirectional
                                    .fromSTEB(
                              9,
                              5,
                              9,
                              5,
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
                            child: Text(
                              'quiz.unlocked_count'
                                  .tr(
                                args: [
                                  unlocked
                                      .toString(),
                                ],
                              ),
                              style:
                                  const TextStyle(
                                fontSize:
                                    10.5,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    _gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (totalLevels > 0) ...[
            const SizedBox(height: 18),

            Row(
              children: [
                Text(
                  'quiz.progress'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color: scheme
                        .onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                Text(
                  '$completed / $totalLevels',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        scheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child:
                  LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    primarySoft,
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  scheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 7),

            Align(
              alignment:
                  AlignmentDirectional
                      .centerEnd,
              child: Text(
                'quiz.completed_percent'
                    .tr(
                  args: [
                    (progress * 100)
                        .round()
                        .toString(),
                  ],
                ),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w700,
                  color: scheme
                      .onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevels() {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final primarySoft = isDark
        ? AppColors.primary.withValues(
            alpha: .15,
          )
        : _primarySoft;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsetsDirectional
              .fromSTEB(
        16,
        2,
        16,
        17,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(
                  color: primarySoft,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  Icons.layers_rounded,
                  size: 17,
                  color:
                      colorScheme.primary,
                ),
              ),

              const SizedBox(width: 9),

              Text(
                'quiz.choose_level'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ListView.separated(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                _levels.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 9,
            ),
            itemBuilder:
                (context, index) {
              final level =
                  _levels[index];

              final levelNumber =
                  _readInt(
                level,
                const [
                  'level',
                  'levelNumber',
                  'level_number',
                ],
                fallback: 1,
              );

              final totalQuestions =
                  _readInt(
                level,
                const [
                  'total_questions',
                  'totalQuestions',
                ],
              );

              final bestScore =
                  _readInt(
                level,
                const [
                  'best_score',
                  'bestScore',
                ],
              );

              final unlocked =
                  _readBool(
                level,
                const [
                  'unlocked',
                  'isUnlocked',
                  'is_unlocked',
                ],
              );

              final completedFlag =
                  _readBool(
                level,
                const [
                  'completed',
                  'isCompleted',
                  'is_completed',
                ],
              );

              final completed =
                  completedFlag &&
                  totalQuestions > 0 &&
                  bestScore ==
                      totalQuestions;

              return QuizLevelCard(
                level: levelNumber,
                totalQuestions:
                    totalQuestions,
                bestScore:
                    bestScore,
                unlocked:
                    unlocked,
                completed:
                    completed,
                onTap: () async {
                  await widget
                      .onOpenLevel(
                    widget.prophetId,
                    levelNumber,
                  );

                  await _loadLevels();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
