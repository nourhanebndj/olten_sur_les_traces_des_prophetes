import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuizResultCard extends StatelessWidget {
  final int score;
  final int total;
  final int level;
  final VoidCallback onBack;
  final VoidCallback? onReplay;
  final VoidCallback? onCorrection;

  const QuizResultCard({
    super.key,
    required this.score,
    required this.total,
    required this.level,
    required this.onBack,
    this.onReplay,
    this.onCorrection,
  });

  static const Color gold = Color(0xFFF0AA25);
  static const Color goldText = Color(0xFFB67E15);
  static const Color correctColor = Color(0xFF3F9463);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final isArabic =
        context.locale.languageCode == 'ar';

    final int percentage = total == 0
        ? 0
        : ((score / total) * 100).round();

    final bool completed =
        total > 0 && score == total;

    final double progress = total == 0
        ? 0
        : (score / total).clamp(0.0, 1.0);

    final Color goldBackground = isDark
        ? gold.withValues(alpha: .15)
        : const Color(0xFFFFF8E8);

    final Color levelBackground = completed
        ? colorScheme.primary.withValues(
            alpha: isDark ? .16 : .08,
          )
        : gold.withValues(
            alpha: isDark ? .15 : .09,
          );

    final Color levelTextColor = completed
        ? colorScheme.primary
        : isDark
            ? const Color(0xFFE8B94F)
            : const Color(0xFF9A701F);

    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding:
                const EdgeInsetsDirectional.fromSTEB(
              18,
              12,
              18,
              14,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius:
                  const BorderRadiusDirectional.only(
                bottomStart: Radius.circular(18),
                bottomEnd: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    isArabic
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),

                Expanded(
                  child: Text(
                    'quiz.result_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 35),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(
                16,
                25,
                16,
                20,
              ),
              child: Column(
                children: [
                  // TROPHÉE
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PositionedDirectional(
                          top: 5,
                          start: 40,
                          child: Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: gold,
                          ),
                        ),

                        PositionedDirectional(
                          top: 18,
                          end: 48,
                          child: Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: gold,
                          ),
                        ),

                        PositionedDirectional(
                          bottom: 12,
                          start: 55,
                          child: Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: gold,
                          ),
                        ),

                        Container(
                          width: 90,
                          height: 90,
                          decoration:
                              BoxDecoration(
                            color: goldBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            completed
                                ? Icons
                                    .emoji_events_rounded
                                : Icons
                                    .workspace_premium_rounded,
                            size: 58,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    completed
                        ? 'quiz.bravo'.tr()
                        : 'quiz.well_played'.tr(),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    completed
                        ? 'quiz.you_got'.tr()
                        : 'quiz.your_result'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$score / $total',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$percentage %',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    completed
                        ? 'quiz.level_completed'.tr()
                        : 'quiz.keep_going'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // PROGRESSION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              'quiz.progress'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
                          child:
                              LinearProgressIndicator(
                            minHeight: 7,
                            value: progress,
                            backgroundColor:
                                colorScheme
                                    .outlineVariant
                                    .withValues(
                              alpha: .55,
                            ),
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NIVEAU
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional
                            .symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: levelBackground,
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          completed
                              ? Icons
                                  .lock_open_rounded
                              : Icons.lock_rounded,
                          size: 20,
                          color: levelTextColor,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            completed
                                ? level == 1
                                    ? 'quiz.level_2_unlocked'
                                        .tr()
                                    : 'quiz.next_level_unlocked'
                                        .tr()
                                : 'quiz.score_to_unlock'
                                    .tr(),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              fontWeight:
                                  FontWeight.w600,
                              color: levelTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // REJOUER
                  if (onReplay != null)
                    SizedBox(
                      width: double.infinity,
                      height: 47,
                      child: ElevatedButton(
                        onPressed: onReplay,
                        style:
                            ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              colorScheme.primary,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: Text(
                          completed
                              ? 'quiz.replay'.tr()
                              : 'quiz.try_again'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  if (onReplay != null)
                    const SizedBox(height: 10),

                  // CORRECTION
                  if (onCorrection != null)
                    SizedBox(
                      width: double.infinity,
                      height: 47,
                      child: OutlinedButton(
                        onPressed: onCorrection,
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              colorScheme.primary,
                          side: BorderSide(
                            color: colorScheme.primary
                                .withValues(
                              alpha: .35,
                            ),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: Text(
                          'quiz.view_correction'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // RETOUR
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            colorScheme
                                .onSurfaceVariant,
                      ),
                      child: Text(
                        'quiz.back_to_levels'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
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
}