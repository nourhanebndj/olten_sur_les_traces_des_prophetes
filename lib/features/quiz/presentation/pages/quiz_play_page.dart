import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../data/local/database_helper.dart';
import '../widgets/quiz_question_card.dart';
import '../widgets/quiz_result_card.dart';

class QuizPlayPage extends StatefulWidget {
  final String prophetId;
  final int level;

  const QuizPlayPage({
    super.key,
    required this.prophetId,
    required this.level,
  });

  @override
  State<QuizPlayPage> createState() =>
      _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  List<Map<String, dynamic>> _questions = [];

  Map<String, dynamic>? _prophet;

  int _currentQuestion = 0;
  int _score = 0;

  int? _selectedAnswer;

  bool _answered = false;
  bool _loading = true;
  bool _finished = false;

  static const Color _green =
      Color(0xFF096B4A);

  static const Color _greenDark =
      Color(0xFF07563C);

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  bool get _isArabic =>
      context.locale.languageCode == 'ar';

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadQuestions() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      await _database.initializeQuizzes();

      final questions =
          await _database.getQuizQuestions(
        widget.prophetId,
        widget.level,
      );

      final prophets =
          await _database.getProphets();

      Map<String, dynamic>? prophet;

      for (final item in prophets) {
        if (item['id']?.toString() ==
            widget.prophetId) {
          prophet = item;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _prophet = prophet;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _questions = [];
        _prophet = null;
        _loading = false;
      });
    }
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
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString();
      }
    }

    return fallback;
  }

  String _getProphetName(
    Map<String, dynamic>? prophet,
  ) {
    if (prophet == null) {
      return _isArabic
          ? 'نبي'
          : 'Prophète';
    }

    if (_isArabic) {
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

  String _getProphetImage() {
    if (_prophet == null) {
      return '';
    }

    return _readString(
      _prophet!,
      const [
        'image',
        'imagePath',
        'image_path',
      ],
    );
  }

  String _getQuestion(
    Map<String, dynamic> question,
  ) {
    if (_isArabic) {
      return _readString(
        question,
        const [
          'questionAr',
          'question_ar',
          'questionFr',
          'question_fr',
        ],
      );
    }

    return _readString(
      question,
      const [
        'questionFr',
        'question_fr',
        'questionAr',
        'question_ar',
      ],
    );
  }

  List<String> _getOptions(
    Map<String, dynamic> question,
  ) {
    final raw = _isArabic
        ? _readString(
            question,
            const [
              'optionsAr',
              'options_ar',
              'optionsFr',
              'options_fr',
            ],
            fallback: '[]',
          )
        : _readString(
            question,
            const [
              'optionsFr',
              'options_fr',
              'optionsAr',
              'options_ar',
            ],
            fallback: '[]',
          );

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .map((item) => item.toString())
            .toList();
      }
    } catch (_) {}

    return [];
  }

  int _getCorrectAnswer(
    Map<String, dynamic> question,
  ) {
    final value =
        question['correct'] ??
        question['correctAnswer'] ??
        question['correct_answer'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // ANSWERS
  // ============================================================

  void _selectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = index;
    });
  }

  void _validateAnswer() {
    if (_selectedAnswer == null ||
        _answered) {
      return;
    }

    final question =
        _questions[_currentQuestion];

    final correct =
        _getCorrectAnswer(question);

    setState(() {
      _answered = true;

      if (_selectedAnswer == correct) {
        _score++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (!_answered) return;

    if (_currentQuestion <
        _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });

      return;
    }

    await _finishQuiz();
  }

  Future<void> _finishQuiz() async {
    await _database.saveQuizResult(
      prophetId: widget.prophetId,
      level: widget.level,
      score: _score,
      total: _questions.length,
    );

    if (!mounted) return;

    setState(() {
      _finished = true;
    });
  }

  void _replay() {
    if (!mounted) return;

    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _finished = false;
    });
  }

  void _goBack() {
    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoading();
    }

    if (_questions.isEmpty) {
      return _buildEmpty();
    }

    if (_finished) {
      return _buildResult();
    }

    return _buildQuiz();
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      body: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child:
              CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
                colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSimpleHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(30),
                  child: Text(
                    'quiz_play.empty_questions'
                        .tr(),
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme
                          .onSurfaceVariant,
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
  // SIMPLE HEADER
  // ============================================================

  Widget _buildSimpleHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        10,
        8,
        16,
        10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:
              AlignmentDirectional.topStart,
          end:
              AlignmentDirectional.bottomEnd,
          colors: [
            _green,
            _greenDark,
          ],
        ),
        borderRadius:
            BorderRadiusDirectional.only(
          bottomStart:
              Radius.circular(18),
          bottomEnd:
              Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: Icon(
              _isArabic
                  ? Icons
                      .arrow_forward_ios_rounded
                  : Icons
                      .arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              'quiz_play.title'.tr(),
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT
  // ============================================================

  Widget _buildResult() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      body: QuizResultCard(
        score: _score,
        total: _questions.length,
        level: widget.level,
        onReplay: _replay,
        onBack: _goBack,
      ),
    );
  }

  // ============================================================
  // QUIZ
  // ============================================================

  Widget _buildQuiz() {
    final question =
        _questions[_currentQuestion];

    final options =
        _getOptions(question);

    final correct =
        _getCorrectAnswer(question);

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
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsetsDirectional.fromSTEB(
                  16,
                  15,
                  16,
                  12,
                ),
                child: QuizQuestionCard(
                  prophetName:
                      _getProphetName(
                    _prophet,
                  ),
                  prophetImage:
                      _getProphetImage(),
                  level: widget.level,
                  currentQuestion:
                      _currentQuestion,
                  totalQuestions:
                      _questions.length,
                  question:
                      _getQuestion(question),
                  options: options,
                  selectedAnswer:
                      _selectedAnswer,
                  correctAnswer: correct,
                  answered: _answered,
                  isArabic: _isArabic,
                  onAnswerSelected:
                      _selectAnswer,
                ),
              ),
            ),

            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        10,
        8,
        16,
        10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:
              AlignmentDirectional.topStart,
          end:
              AlignmentDirectional.bottomEnd,
          colors: [
            _green,
            _greenDark,
          ],
        ),
        borderRadius:
            BorderRadiusDirectional.only(
          bottomStart:
              Radius.circular(18),
          bottomEnd:
              Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: Icon(
              _isArabic
                  ? Icons
                      .arrow_forward_ios_rounded
                  : Icons
                      .arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  'quiz_play.solo'.tr(),
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'quiz_play.level'.tr(
                    args: [
                      widget.level
                          .toString(),
                    ],
                  ),
                  style:
                      const TextStyle(
                    color:
                        Color(0xFFD7EDE3),
                    fontSize: 10.5,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    final colorScheme =
        Theme.of(context).colorScheme;

    final bool canValidate =
        _selectedAnswer != null &&
        !_answered;

    final bool lastQuestion =
        _currentQuestion ==
            _questions.length - 1;

    final bool isCorrect =
        _answered &&
        _selectedAnswer ==
            _getCorrectAnswer(
              _questions[
                  _currentQuestion],
            );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsetsDirectional.fromSTEB(
        16,
        8,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme
                .outlineVariant
                .withValues(alpha: .5),
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _answered
                  ? _nextQuestion
                  : canValidate
                      ? _validateAnswer
                      : null,
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    colorScheme.primary,
                disabledBackgroundColor:
                    colorScheme
                        .surfaceContainerHighest,
                disabledForegroundColor:
                    colorScheme
                        .onSurfaceVariant,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              child: Text(
                !_answered
                    ? 'quiz_play.validate'
                        .tr()
                    : lastQuestion
                        ? 'quiz_play.see_result'
                            .tr()
                        : 'quiz_play.next_question'
                            .tr(),
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),

          if (_answered) ...[
            const SizedBox(height: 7),

            Text(
              isCorrect
                  ? 'quiz_play.correct'
                      .tr()
                  : 'quiz_play.correct_answer'
                      .tr(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w700,
                color: isCorrect
                    ? const Color(
                        0xFF3F9463,
                      )
                    : colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}