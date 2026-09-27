import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/online_quiz_service.dart';

class MultiplayerQuizPage extends StatefulWidget {
  final String matchId;
  final int level;

  const MultiplayerQuizPage({
    super.key,
    required this.matchId,
    required this.level,
  });

  @override
  State<MultiplayerQuizPage> createState() =>
      _MultiplayerQuizPageState();
}

class _MultiplayerQuizPageState
    extends State<MultiplayerQuizPage> {
  final OnlineQuizService _service =
      OnlineQuizService.instance;

  Timer? _timer;
  RealtimeChannel? _matchChannel;

  List<Map<String, dynamic>> _questions = [];

  int _currentQuestion = 0;
  int _remainingSeconds = 180;

  bool _loading = true;
  bool _answering = false;
  bool _finished = false;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.heartbeat();

      final match = await _service.getMatch(
        widget.matchId,
      );

      final questions =
          await _service.getMatchQuestions(
        widget.matchId,
      );

      final endsAt = DateTime.parse(
        match['ends_at'].toString(),
      ).toLocal();

      final seconds = endsAt
          .difference(DateTime.now())
          .inSeconds;

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _remainingSeconds = seconds.clamp(0, 180);
        _loading = false;
      });

      _startTimer();

      _matchChannel = _service.watchMatch(
        matchId: widget.matchId,
        onMatchChanged: _onMatchChanged,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(e);
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _finished) return;

        if (_remainingSeconds <= 0) {
          _finishMatch();
          return;
        }

        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds == 0) {
          _finishMatch();
        }
      },
    );
  }

  void _onMatchChanged(
    Map<String, dynamic> match,
  ) {
    if (match['status'] == 'finished') {
      _showResult();
    }
  }

  Future<void> _answer(int answerIndex) async {
    if (_answering ||
        _finished ||
        _remainingSeconds <= 0) {
      return;
    }

    if (_currentQuestion >= _questions.length) {
      return;
    }

    final question = _questions[_currentQuestion];

    setState(() {
      _answering = true;
    });

    try {
      await _service.submitAnswer(
        matchId: widget.matchId,
        questionId: question['id'].toString(),
        answerIndex: answerIndex,
      );

      if (!mounted) return;

      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _answering = false;
        });
      } else {
        setState(() {
          _answering = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _answering = false;
      });

      _showError(e);
    }
  }

  Future<void> _finishMatch() async {
    if (_finished) return;

    try {
      await _service.finishMatch(
        widget.matchId,
      );

      await _showResult();
    } catch (e) {
      if (e.toString().contains('pas encore terminé')) {
        return;
      }

      _showError(e);
    }
  }

  Future<void> _showResult() async {
    if (_resultShown) return;

    _resultShown = true;
    _finished = true;

    _timer?.cancel();

    try {
      final result = await _service.finishMatch(
        widget.matchId,
      );

      if (!mounted) return;

      final winnerId =
          result['winner_id']?.toString();

      final player1Id =
          result['player1_id']?.toString();

      final player1Score =
          (result['player1_score'] as num?)?.toInt() ?? 0;

      final player2Score =
          (result['player2_score'] as num?)?.toInt() ?? 0;

      final myId = _service.userId;

      final myScore = player1Id == myId
          ? player1Score
          : player2Score;

      final opponentScore = player1Id == myId
          ? player2Score
          : player1Score;

      String title;
      IconData resultIcon;

      if (winnerId == null) {
        title = 'draw'.tr();
        resultIcon = Icons.handshake_rounded;
      } else if (winnerId == myId) {
        title = 'victory'.tr();
        resultIcon = Icons.emoji_events_rounded;
      } else {
        title = 'defeat'.tr();
        resultIcon = Icons.sentiment_dissatisfied_rounded;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final colors =
              Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            backgroundColor: colors.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              10,
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              10,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              20,
            ),
            title: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    resultIcon,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _scoreRow(
                  dialogContext,
                  'your_score'.tr(),
                  myScore,
                  true,
                ),
                const SizedBox(height: 10),
                _scoreRow(
                  dialogContext,
                  'opponent'.tr(),
                  opponentScore,
                  false,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'finish'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _resultShown = false;
      _finished = false;

      if (mounted) {
        _showError(e);
      }
    }
  }

  Widget _scoreRow(
    BuildContext context,
    String label,
    int score,
    bool isMe,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withOpacity(.08)
            : colors.onSurface.withOpacity(.05),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: isMe
                  ? AppColors.primary
                  : colors.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _showError(Object error) {
    if (!mounted) return;

    final message = error
        .toString()
        .replaceFirst('Exception: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    if (_matchChannel != null) {
      _service.removeChannel(_matchChannel!);
    }

    _service.setOnline(false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          title: Text(
            'online_quiz'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 60,
                  color: colors.onSurface.withOpacity(.35),
                ),
                const SizedBox(height: 15),
                Text(
                  'no_questions'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentQuestion];

    final options = List<dynamic>.from(
      question['options'] ?? [],
    );

    final progress =
        (_currentQuestion + 1) / _questions.length;

    final isDanger = _remainingSeconds <= 30;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'online_quiz'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 15,
              top: 8,
              bottom: 8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isDanger
                  ? Colors.red.withOpacity(.10)
                  : AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: isDanger
                      ? Colors.red
                      : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDanger
                        ? Colors.red
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            30,
          ),
          children: [
            _buildPlayersHeader(),
            const SizedBox(height: 18),
            _buildQuestionProgress(progress),
            const SizedBox(height: 20),
            _buildQuestionCard(question),
            const SizedBox(height: 18),
            _buildAnswers(options),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersHeader() {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _playerChip(
            icon: Icons.person_rounded,
            label: 'you'.tr(),
            color: AppColors.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flash_on_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: _playerChip(
            icon: Icons.person_outline_rounded,
            label: 'opponent'.tr(),
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _playerChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionProgress(double progress) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${'question'.tr()} ${_currentQuestion + 1} / ${_questions.length}',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor:
                colors.onSurface.withOpacity(.08),
            valueColor:
                AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.primary.withOpacity(.10),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            question['question']?.toString() ?? '',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 21,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswers(List<dynamic> options) {
    return Column(
      children: List.generate(
        options.length,
        (index) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: _buildAnswerButton(
              index,
              options[index].toString(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnswerButton(
    int index,
    String text,
  ) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _answering
              ? null
              : () => _answer(index),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 62,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withOpacity(.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.09),
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_answering)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: colors.onSurface.withOpacity(.35),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}