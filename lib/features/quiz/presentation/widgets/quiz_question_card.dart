import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuizQuestionCard extends StatelessWidget {
  final String prophetName;
  final String prophetImage;
  final int level;
  final int currentQuestion;
  final int totalQuestions;
  final String question;
  final List<String> options;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool answered;
  final bool isArabic;
  final ValueChanged<int> onAnswerSelected;

  const QuizQuestionCard({
    super.key,
    required this.prophetName,
    required this.prophetImage,
    required this.level,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.question,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.answered,
    required this.isArabic,
    required this.onAnswerSelected,
  });

  static const Color gold = Color(0xFFE4A52B);
  static const Color correctColor = Color(0xFF3F9463);
  static const Color wrongColor = Color(0xFFD65A4A);

  double get progress {
    if (totalQuestions <= 0) return 0;

    return ((currentQuestion + 1) / totalQuestions).clamp(0.0, 1.0);
  }

  Color _optionBackground(
    BuildContext context,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    if (!answered) {
      return selectedAnswer == index
          ? colorScheme.primary.withValues(
              alpha: isDark ? .18 : .07,
            )
          : colorScheme.surface;
    }

    if (index == correctAnswer) {
      return correctColor.withValues(
        alpha: isDark ? .18 : .08,
      );
    }

    if (index == selectedAnswer) {
      return wrongColor.withValues(
        alpha: isDark ? .18 : .08,
      );
    }

    return colorScheme.surface;
  }

  Color _optionBorder(
    BuildContext context,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!answered) {
      return selectedAnswer == index
          ? colorScheme.primary
          : colorScheme.outlineVariant;
    }

    if (index == correctAnswer) {
      return correctColor;
    }

    if (index == selectedAnswer) {
      return wrongColor;
    }

    return colorScheme.outlineVariant;
  }

  Widget _buildProphetImage(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color background = colorScheme.primary.withValues(
      alpha: isDark ? .18 : .08,
    );

    if (prophetImage.isEmpty) {
      return Container(
        width: 57,
        height: 57,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          color: colorScheme.primary,
          size: 27,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        prophetImage,
        width: 57,
        height: 57,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: colorScheme.primary,
              size: 27,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCard(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color greenSoft = colorScheme.primary.withValues(
      alpha: isDark ? .18 : .08,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? .12 : .035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProphetImage(context),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      prophetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: greenSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'quiz.level'.tr(
                          args: [
                            level.toString(),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentQuestion + 1}/$totalQuestions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'quiz.question'.tr(),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        colorScheme.outlineVariant.withValues(
                      alpha: .55,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        17,
        16,
        17,
        17,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        question,
        textAlign: isArabic
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontSize: 17,
          height: 1.4,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    int index,
    String option,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool selected = selectedAnswer == index;

    final bool correct =
        answered && index == correctAnswer;

    final bool wrong =
        answered &&
        selected &&
        index != correctAnswer;

    final Color accent = correct
        ? correctColor
        : wrong
            ? wrongColor
            : selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant;

    final Color indicatorBackground = correct
        ? correctColor
        : wrong
            ? wrongColor
            : selected
                ? colorScheme.primary
                : colorScheme.surface;

    return GestureDetector(
      onTap: answered
          ? null
          : () => onAnswerSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsetsDirectional.only(
          bottom: 9,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _optionBackground(
            context,
            index,
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _optionBorder(
              context,
              index,
            ),
            width:
                selected || correct || wrong
                    ? 1.5
                    : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorBackground,
                border: Border.all(
                  color: accent,
                  width: 1.5,
                ),
              ),
              child: correct || wrong
                  ? Icon(
                      correct
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 15,
                    )
                  : selected
                      ? const Center(
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.white,
                          ),
                        )
                      : null,
            ),

            const SizedBox(width: 11),

            SizedBox(
              width: 24,
              child: Text(
                String.fromCharCode(65 + index),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                option,
                textAlign: isArabic
                    ? TextAlign.right
                    : TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopCard(context),

        const SizedBox(height: 14),

        _buildQuestion(context),

        const SizedBox(height: 13),

        ...List.generate(
          options.length,
          (index) => _buildOption(
            context,
            index,
            options[index],
          ),
        ),
      ],
    );
  }
}