import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuizLevelCard extends StatelessWidget {
  final int level;
  final int totalQuestions;
  final int bestScore;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;

  const QuizLevelCard({
    super.key,
    required this.level,
    required this.totalQuestions,
    required this.bestScore,
    required this.unlocked,
    required this.completed,
    this.onTap,
  });

  static const Color green = Color(0xFF096B4A);
  static const Color greenDark = Color(0xFF075A3E);
  static const Color greenSoft = Color(0xFFEAF6EF);
  static const Color gold = Color(0xFFE7A928);
  static const Color goldSoft = Color(0xFFFFF6DF);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final isArabic =
        context.locale.languageCode == 'ar';

    final bool finished =
        completed &&
        totalQuestions > 0 &&
        bestScore == totalQuestions;

    final double progress = totalQuestions == 0
        ? 0
        : (bestScore / totalQuestions).clamp(0.0, 1.0);

    final Color accent = !unlocked
        ? colorScheme.onSurfaceVariant
        : finished
            ? colorScheme.primary
            : gold;

    final Color background = !unlocked
        ? colorScheme.surfaceContainerHighest
        : finished
            ? isDark
                ? colorScheme.primary.withValues(alpha: .13)
                : greenSoft
            : colorScheme.surface;

    final Color borderColor = finished
        ? colorScheme.primary.withValues(
            alpha: isDark ? .35 : .25,
          )
        : colorScheme.outlineVariant;

    final Color iconBackground = !unlocked
        ? colorScheme.surfaceContainerHighest
        : finished
            ? colorScheme.primary.withValues(
                alpha: isDark ? .18 : .12,
              )
            : isDark
                ? gold.withValues(alpha: .14)
                : goldSoft;

    final Color completedBadgeBackground =
        colorScheme.primary.withValues(
      alpha: isDark ? .18 : .12,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              _buildLevelIcon(
                context,
                accent,
                finished,
                iconBackground,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'quiz.level'.tr(
                              args: [
                                level.toString(),
                              ],
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                              color: unlocked
                                  ? colorScheme.onSurface
                                  : colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),

                        const SizedBox(width: 7),

                        if (finished)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  completedBadgeBackground,
                              borderRadius:
                                  BorderRadius.circular(7),
                            ),
                            child: Text(
                              'quiz.completed'.tr(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'quiz.questions'.tr(
                        args: [
                          totalQuestions.toString(),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color:
                            colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (unlocked &&
                        bestScore > 0) ...[
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(10),
                              child:
                                  LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor:
                                    colorScheme
                                        .outlineVariant
                                        .withValues(
                                      alpha: .55,
                                    ),
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  accent,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '$bestScore/$totalQuestions',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _buildTrailing(
                context,
                accent,
                finished,
                isArabic,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIcon(
    BuildContext context,
    Color accent,
    bool finished,
    Color background,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: !unlocked
            ? Icon(
                Icons.lock_rounded,
                color:
                    colorScheme.onSurfaceVariant,
                size: 21,
              )
            : finished
                ? Icon(
                    Icons.check_rounded,
                    color: colorScheme.primary,
                    size: 25,
                  )
                : Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB67E15),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    Color accent,
    bool finished,
    bool isArabic,
  ) {
    if (!unlocked) {
      return Icon(
        Icons.lock_outline_rounded,
        size: 19,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      );
    }

    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final background = finished
        ? colorScheme.primary.withValues(
            alpha: isDark ? .18 : .12,
          )
        : isDark
            ? gold.withValues(alpha: .14)
            : goldSoft;

    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: isArabic
            ? Matrix4.rotationY(3.141592653589793)
            : Matrix4.identity(),
        child: Icon(
          finished
              ? Icons.check_rounded
              : Icons.arrow_forward_rounded,
          size: 17,
          color: accent,
        ),
      ),
    );
  }
}

