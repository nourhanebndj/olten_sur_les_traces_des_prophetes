import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/widgets/bottom_menu.dart';
import '../../../../data/local/database_helper.dart';
import '../../../quiz/presentation/pages/quiz_play_page.dart';
import '../../services/prophets_pdf_service.dart';

class ProphetDetailPage extends StatefulWidget {
  final String prophetId;

  const ProphetDetailPage({
    super.key,
    required this.prophetId,
  });

  @override
  State<ProphetDetailPage> createState() => _ProphetDetailPageState();
}

class _ProphetDetailPageState extends State<ProphetDetailPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _prophet;

  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _quizLevels = [];

  final Map<int, List<String>> _quranReferences = {};
  final Map<int, List<String>> _lessons = {};

  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  String? _error;

  static const Color _gold = Color(0xFFC79A3F);
  static const Color _danger = Color(0xFFC0574A);

  // ============================================================
  // LANGUAGE
  // ============================================================

  bool get _isArabic => context.locale.languageCode == 'ar';

  String get _language => _isArabic ? 'ar' : 'fr';

  IconData get _backIcon => _isArabic
      ? Icons.arrow_forward_rounded
      : Icons.arrow_back_rounded;

  IconData get _forwardIcon => _isArabic
      ? Icons.chevron_left_rounded
      : Icons.chevron_right_rounded;

  // ============================================================
  // THEME
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _primary => Theme.of(context).colorScheme.primary;

  Color get _primaryDark {
    return _isDark
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF1F5B41);
  }

  Color get _surface => Theme.of(context).colorScheme.surface;

  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  Color get _textSecondary =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _outline =>
      Theme.of(context).colorScheme.outlineVariant;

  Color get _primarySoft => _primary.withValues(
        alpha: _isDark ? 0.16 : 0.09,
      );

  Color get _goldSoft => _gold.withValues(
        alpha: _isDark ? 0.16 : 0.10,
      );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prophet = await _databaseHelper.getProphet(
        widget.prophetId,
      );

      if (prophet == null) {
        throw Exception('prophets.errors.not_found'.tr());
      }

      final stories = await _databaseHelper.getStories(
        widget.prophetId,
        audience: 'adult',
      );

      final quizLevels = await _databaseHelper.getQuizLevels(
        widget.prophetId,
      );

      final Map<int, List<String>> quranReferences = {};
      final Map<int, List<String>> lessons = {};

      for (final story in stories) {
        final dynamic rawId = story['id'];

        if (rawId == null) {
          continue;
        }

        final int storyId = rawId is int
            ? rawId
            : int.tryParse(rawId.toString()) ?? 0;

        if (storyId == 0) {
          continue;
        }

        final references =
            await _databaseHelper.getQuranReferences(storyId);

        final storyLessons = await _databaseHelper.getLessons(
          storyId,
          _language,
        );

        quranReferences[storyId] =
            references.map((e) => e.toString()).toList();

        lessons[storyId] =
            storyLessons.map((e) => e.toString()).toList();
      }

      if (!mounted) return;

      setState(() {
        _prophet = prophet;
        _stories = stories;
        _quizLevels = quizLevels;

        _quranReferences
          ..clear()
          ..addAll(quranReferences);

        _lessons
          ..clear()
          ..addAll(lessons);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // QUIZ
  // ============================================================

  Future<void> _openQuiz(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizPlayPage(
          prophetId: widget.prophetId,
          level: level,
        ),
      ),
    );

    if (!mounted) return;

    await _loadData();
  }

  // ============================================================
  // PDF
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_prophet == null || _isGeneratingPdf) {
      return;
    }

    try {
      setState(() {
        _isGeneratingPdf = true;
      });

      await ProphetsPdfService.generateAndDownload(
        prophet: _prophet!,
        stories: _stories,
        quranReferences: _quranReferences,
        lessons: _lessons,
      );

      if (!mounted) return;

      _showSnackBar(
        message: 'prophet_details.pdf.success'.tr(),
        icon: Icons.check_circle_rounded,
        color: _primary,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        message: 'prophet_details.pdf.error'.tr(),
        icon: Icons.error_outline_rounded,
        color: _danger,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _isLoading
          ? _buildLoading()
          : (_error != null || _prophet == null)
              ? SafeArea(
                  child: _buildError(),
                )
              : _buildBody(),
      bottomNavigationBar: const BottomMenu(
        currentIndex: 1,
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: 34,
        height: 34,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _primary,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return RefreshIndicator(
      color: _primary,
      backgroundColor: _surface,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            backgroundColor: _background,
            expandedHeight: 320,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: _buildHero(),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsRow(),
                _buildSummary(),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: _buildSectionTitle(
              'prophet_details.stories'.tr(),
              Icons.auto_stories_rounded,
            ),
          ),

          if (_stories.isEmpty)
            SliverToBoxAdapter(
              child: _buildNoStories(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final story = _stories[index];

                  return _buildStoryCard(
                    story,
                    index,
                  );
                },
                childCount: _stories.length,
              ),
            ),

          if (_quizLevels.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildQuizSection(),
            ),

          SliverToBoxAdapter(
            child: _buildDownloadPdfButton(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 34),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    final prophet = _prophet!;

    final String name = _getProphetName(
      context,
      prophet,
    );

    final String arabicName = _readString(
      prophet,
      const [
        'nameAr',
        'name_ar',
        'arabic_name',
        'nom_ar',
      ],
    );

    final String image = _readString(
      prophet,
      const [
        'image',
        'image_path',
        'image_url',
      ],
    );

    final String number = _readString(
      prophet,
      const [
        'number',
        'order',
        'id',
      ],
    );

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildHeroImage(image),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xE6000000),
                ],
                stops: [
                  0.0,
                  0.45,
                  1.0,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(
                    icon: _backIcon,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildPdfTopButton(),
                ],
              ),
            ),
          ),

          PositionedDirectional(
            start: 22,
            end: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (number.isNotEmpty)
                  Container(
                    margin: const EdgeInsetsDirectional.only(
                      bottom: 12,
                    ),
                    padding:
                        const EdgeInsetsDirectional.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _gold,
                          Color(0xFFDBB35C),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'prophet_details.prophet_number'
                          .tr(
                        args: [number],
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: -0.4,
                  ),
                ),

                if (arabicName.isNotEmpty &&
                    !_isArabic) ...[
                  const SizedBox(height: 6),
                  Text(
                    arabicName,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.88,
                      ),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroImage(String image) {
    if (image.isEmpty) {
      return _buildImageFallback();
    }

    if (image.startsWith('http://') ||
        image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImageFallback();
        },
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _buildImageFallback();
      },
    );
  }

  // ============================================================
  // GLASS BUTTON
  // ============================================================

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white.withValues(
          alpha: 0.16,
        ),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.28,
                ),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PDF TOP BUTTON
  // ============================================================

  Widget _buildPdfTopButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white.withValues(
          alpha: 0.16,
        ),
        child: InkWell(
          onTap: _isGeneratingPdf
              ? null
              : _downloadPdf,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.28,
                ),
                width: 1,
              ),
            ),
            child: Center(
              child: _isGeneratingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow() {
    final int storiesCount = _stories.length;

    final int referencesCount =
        _quranReferences.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    final int lessonsCount =
        _lessons.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        18,
        18,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              icon: Icons.auto_stories_rounded,
              value: storiesCount,
              label: 'prophet_details.stories'.tr(),
              color: _primary,
              bg: _primarySoft,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _buildStatChip(
              icon: Icons.menu_book_rounded,
              value: referencesCount,
              label:
                  'prophet_details.references'.tr(),
              color: _primaryDark,
              bg: _primarySoft,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _buildStatChip(
              icon: Icons.lightbulb_rounded,
              value: lessonsCount,
              label: 'prophet_details.lessons'.tr(),
              color: _gold,
              bg: _goldSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: 14,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final summary = _getProphetSummary(
      context,
      _prophet!,
    );

    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        16,
        18,
        4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark ? 0.12 : 0.035,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary,
                        _primaryDark,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 11),

                Text(
                  'prophet_details.about'.tr(),
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              summary,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.5,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        26,
        18,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _primary,
                  _gold,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            title,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STORY CARD
  // ============================================================

  Widget _buildStoryCard(
    Map<String, dynamic> story,
    int index,
  ) {
    final dynamic rawId = story['id'];

    final int storyId = rawId is int
        ? rawId
        : int.tryParse(
              rawId?.toString() ?? '',
            ) ??
            0;

    final String title = _getStoryTitle(
      context,
      story,
      fallback:
          'prophet_details.story'.tr(
        args: ['${index + 1}'],
      ),
    );

    final String content = _getStoryContent(
      context,
      story,
    );

    final references =
        _quranReferences[storyId] ?? [];

    final lessons =
        _lessons[storyId] ?? [];

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        0,
        18,
        12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark ? 0.10 : 0.03,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor:
                _primary.withValues(alpha: 0.06),
            highlightColor:
                _primary.withValues(alpha: 0.03),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding:
                const EdgeInsetsDirectional.fromSTEB(
              16,
              0,
              16,
              18,
            ),
            iconColor: _primary,
            collapsedIconColor: _textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            collapsedShape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primary.withValues(
                      alpha: 0.12,
                    ),
                    _primary.withValues(
                      alpha: 0.06,
                    ),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: _primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            children: [
              if (content.isNotEmpty)
                _buildStoryContent(content),

              if (references.isNotEmpty)
                _buildQuranReferences(
                  references,
                ),

              if (lessons.isNotEmpty)
                _buildLessons(lessons),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STORY CONTENT
  // ============================================================

  Widget _buildStoryContent(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsetsDirectional.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        content,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 14,
          height: 1.7,
        ),
      ),
    );
  }

  // ============================================================
  // QURAN REFERENCES
  // ============================================================

  Widget _buildQuranReferences(
    List<String> references,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: _primaryDark,
              ),

              const SizedBox(width: 8),

              Text(
                'prophet_details.quran_references'
                    .tr(),
                style: TextStyle(
                  color: _primaryDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ...references.map(
            (reference) => Padding(
              padding:
                  const EdgeInsetsDirectional.only(
                bottom: 7,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:
                        const EdgeInsetsDirectional.only(
                      top: 6,
                    ),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      reference,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LESSONS
  // ============================================================

  Widget _buildLessons(
    List<String> lessons,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goldSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: _gold,
              ),

              const SizedBox(width: 8),

              Text(
                'prophet_details.lessons_to_remember'
                    .tr(),
                style: TextStyle(
                  color: _isDark
                      ? _gold
                      : const Color(0xFFA07A2A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ...lessons.map(
            (lesson) => Padding(
              padding:
                  const EdgeInsetsDirectional.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: _gold,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      lesson,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUIZ SECTION
  // ============================================================

  Widget _buildQuizSection() {
    final int completedLevels =
        _quizLevels.where((level) {
      final int total =
          _toInt(level['total_questions']);

      final int best =
          _toInt(level['best_score']);

      final int completed =
          _toInt(level['completed']);

      return completed == 1 &&
          total > 0 &&
          best == total;
    }).length;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        18,
        26,
        18,
        4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark ? 0.10 : 0.03,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gold,
                        Color(0xFFDBB35C),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.all(
                      Radius.circular(13),
                    ),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'prophet_details.quiz.title'
                            .tr(),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'prophet_details.quiz.subtitle'
                            .tr(),
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedLevels/${_quizLevels.length}',
                    style: TextStyle(
                      color: _primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ..._quizLevels.map(
              (level) =>
                  _buildQuizLevelCard(level),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUIZ LEVEL CARD
  // ============================================================

  Widget _buildQuizLevelCard(
    Map<String, dynamic> levelData,
  ) {
    final int level =
        _toInt(
          levelData['level'],
          fallback: 1,
        );

    final int totalQuestions =
        _toInt(
          levelData['total_questions'],
        );

    final int bestScore =
        _toInt(
          levelData['best_score'],
        );

    final int completed =
        _toInt(
          levelData['completed'],
        );

    final int unlocked =
        _toInt(
          levelData['unlocked'],
        );

    final bool isUnlocked =
        unlocked == 1;

    final bool isCompleted =
        completed == 1 &&
        totalQuestions > 0 &&
        bestScore == totalQuestions;

    final bool hasAttempt =
        bestScore > 0 && !isCompleted;

    final Color levelBackground =
        isUnlocked
            ? _primarySoft
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest;

    final Color levelBorder =
        isUnlocked
            ? _primary.withValues(
                alpha: 0.14,
              )
            : _outline;

    return Container(
      margin:
          const EdgeInsetsDirectional.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: levelBackground,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: levelBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(17),
          onTap: isUnlocked
              ? () => _openQuiz(level)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? _surface
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isUnlocked
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                    color: isUnlocked
                        ? _primary
                        : _textSecondary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'prophet_details.quiz.level'
                                  .tr(
                                args: ['$level'],
                              ),
                              style: TextStyle(
                                color: isUnlocked
                                    ? _textPrimary
                                    : _textSecondary,
                                fontSize: 14.5,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),

                          if (isCompleted) ...[
                            const SizedBox(width: 7),

                            Container(
                              padding:
                                  const EdgeInsetsDirectional
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: _goldSoft,
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Text(
                                'prophet_details.quiz.completed_badge'
                                    .tr(),
                                style:
                                    const TextStyle(
                                  color: _gold,
                                  fontSize: 9.5,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      if (isCompleted)
                        Text(
                          'prophet_details.quiz.questions_completed'
                              .tr(
                            args: [
                              '$totalQuestions',
                            ],
                          ),
                          style: TextStyle(
                            color: _primaryDark,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        )
                      else if (hasAttempt)
                        Text(
                          'prophet_details.quiz.questions_best'
                              .tr(
                            args: [
                              '$totalQuestions',
                              '$bestScore',
                              '$totalQuestions',
                            ],
                          ),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        )
                      else if (isUnlocked)
                        Text(
                          'prophet_details.quiz.questions_unlock_next'
                              .tr(
                            args: [
                              '$totalQuestions',
                            ],
                          ),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          'prophet_details.quiz.locked'
                              .tr(),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsetsDirectional
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _goldSoft,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: _gold,
                      size: 18,
                    ),
                  ),

                const SizedBox(width: 5),

                Icon(
                  isUnlocked
                      ? _forwardIcon
                      : Icons.lock_outline_rounded,
                  color: isUnlocked
                      ? _primary
                      : _textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PDF BUTTON
  // ============================================================

  Widget _buildDownloadPdfButton() {
    final Color disabledColor =
        Theme.of(context)
            .colorScheme
            .surfaceContainerHighest;

    return Padding(
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        18,
        22,
        18,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _isGeneratingPdf
                ? null
                : LinearGradient(
                    colors: [
                      _primary,
                      _primaryDark,
                    ],
                  ),
            color: _isGeneratingPdf
                ? disabledColor
                : null,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: _isGeneratingPdf
                ? []
                : [
                    BoxShadow(
                      color: _primary.withValues(
                        alpha: 0.32,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(20),
              onTap: _isGeneratingPdf
                  ? null
                  : _downloadPdf,
              child: Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    if (_isGeneratingPdf)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 22,
                      ),

                    const SizedBox(width: 11),

                    Text(
                      _isGeneratingPdf
                          ? 'prophet_details.pdf.generating'
                              .tr()
                          : 'prophet_details.pdf.download'
                              .tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NO STORIES
  // ============================================================

  Widget _buildNoStories() {
    return Padding(
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        18,
        6,
        18,
        10,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: _outline,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: _primary,
                size: 28,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'prophet_details.empty_stories'
                  .tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE FALLBACK
  // ============================================================

  Widget _buildImageFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary,
            _primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white.withValues(
            alpha: 0.85,
          ),
          size: 74,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    final Color errorBackground =
        _danger.withValues(
      alpha: _isDark ? 0.16 : 0.10,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: errorBackground,
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _danger,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'prophet_details.errors.data'
                  .tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            if (_error != null)
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
              ),

            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                ),
                label: Text(
                  'common.retry'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsetsDirectional
                          .symmetric(
                    horizontal: 24,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
  // PROPHET NAME
  // ============================================================

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

  // ============================================================
  // PROPHET SUMMARY
  // ============================================================

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

  // ============================================================
  // STORY TITLE
  // ============================================================

  String _getStoryTitle(
    BuildContext context,
    Map<String, dynamic> story, {
    String fallback = '',
  }) {
    final isArabic =
        context.locale.languageCode == 'ar';

    if (isArabic) {
      return _readString(
        story,
        const [
          'titleAr',
          'title_ar',
          'titleFr',
          'title_fr',
        ],
        fallback: fallback,
      );
    }

    return _readString(
      story,
      const [
        'titleFr',
        'title_fr',
        'titleAr',
        'title_ar',
      ],
      fallback: fallback,
    );
  }

  // ============================================================
  // STORY CONTENT
  // ============================================================

  String _getStoryContent(
    BuildContext context,
    Map<String, dynamic> story,
  ) {
    final isArabic =
        context.locale.languageCode == 'ar';

    if (isArabic) {
      return _readString(
        story,
        const [
          'contentAr',
          'content_ar',
          'contentFr',
          'content_fr',
        ],
      );
    }

    return _readString(
      story,
      const [
        'contentFr',
        'content_fr',
        'contentAr',
        'content_ar',
      ],
    );
  }

  // ============================================================
  // GENERIC STRING HELPER
  // ============================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null) {
        final stringValue =
            value.toString().trim();

        if (stringValue.isNotEmpty &&
            stringValue != 'null') {
          return stringValue;
        }
      }
    }

    return fallback;
  }

  // ============================================================
  // INT HELPER
  // ============================================================

  int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is bool) {
      return value ? 1 : 0;
    }

    if (value != null) {
      return int.tryParse(
            value.toString(),
          ) ??
          fallback;
    }

    return fallback;
  }
}