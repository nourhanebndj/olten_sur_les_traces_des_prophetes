import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/online_quiz_service.dart';
import '../../../../core/widgets/bottom_menu.dart';
import 'multiplayer_quiz_page.dart';

class MatchmakingPage extends StatefulWidget {
  const MatchmakingPage({super.key});

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  final OnlineQuizService _service = OnlineQuizService.instance;

  Timer? _searchTimer;
  Timer? _heartbeatTimer;

  int _currentLevel = 0;
  int _levelWins = 0;

  bool _loading = true;
  bool _searching = false;
  bool _creatingFriendMatch = false;

  List<Map<String, dynamic>> _friends = [];

  static const List<String> _levels = [
    'level_beginner',
    'level_intermediate',
    'level_advanced',
    'level_expert',
    'level_master',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.setOnline(true);

      final results = await Future.wait([
        _service.getMyProfile(),
        _service.getFriends(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final friends =
          results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _currentLevel =
            (profile['current_level'] as num?)?.toInt() ?? 0;
        _levelWins =
            (profile['level_wins'] as num?)?.toInt() ?? 0;
        _friends = friends;
        _loading = false;
      });

      _startHeartbeat();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(e);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _heartbeat(),
    );
  }

  Future<void> _heartbeat() async {
    try {
      await _service.heartbeat();

      final friends = await _service.getFriends();

      if (!mounted) return;

      setState(() {
        _friends = friends;
      });
    } catch (_) {}
  }

  Future<void> _startRandomMatch() async {
    if (_searching) return;

    setState(() {
      _searching = true;
    });

    try {
      final matchId =
          await _service.joinRandomMatch(_currentLevel);

      if (!mounted) return;

      if (matchId != null) {
        _openMatch(matchId);
        return;
      }

      _searchTimer?.cancel();

      _searchTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkForMatch(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searching = false;
      });

      _showError(e);
    }
  }

  Future<void> _checkForMatch() async {
    if (!_searching) return;

    try {
      final match = await _service.findActiveMatch();

      if (match == null) return;
      if (match['status'] != 'playing') return;

      final matchId = match['id'].toString();

      _searchTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _searching = false;
      });

      _openMatch(matchId);
    } catch (_) {}
  }

  Future<void> _cancelSearch() async {
    _searchTimer?.cancel();

    try {
      await _service.leaveQueue();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _searching = false;
    });
  }

  Future<void> _playWithFriend(
    Map<String, dynamic> friend,
  ) async {
    if (_creatingFriendMatch) return;

    setState(() {
      _creatingFriendMatch = true;
    });

    try {
      final matchId = await _service.createFriendMatch(
        friendId: friend['id'].toString(),
        level: _currentLevel,
      );

      if (!mounted) return;

      _openMatch(matchId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _creatingFriendMatch = false;
      });

      _showError(e);
    }
  }

  void _openMatch(String matchId) {
    _searchTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _searching = false;
      _creatingFriendMatch = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerQuizPage(
          matchId: matchId,
          level: _currentLevel,
        ),
      ),
    ).then((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _service.getMyProfile(),
        _service.getFriends(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final friends =
          results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _currentLevel =
            (profile['current_level'] as num?)?.toInt() ?? 0;
        _levelWins =
            (profile['level_wins'] as num?)?.toInt() ?? 0;
        _friends = friends;
      });
    } catch (_) {}
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
    _searchTimer?.cancel();
    _heartbeatTimer?.cancel();

    _service.leaveQueue();
    _service.setOnline(false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'online_quiz'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            30,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildProgressCard(),
            const SizedBox(height: 18),
            _buildRandomMatchCard(),
            const SizedBox(height: 26),
            _buildFriendsHeader(),
            const SizedBox(height: 12),
            _buildFriends(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomMenu(
        currentIndex: 2,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'online_challenge'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'online_challenge_description'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.88),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress =
        (_levelWins / 10).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'your_level'.tr(),
                      style: TextStyle(
                        color:
                            colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _levels[_currentLevel].tr(),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withOpacity(.09),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Text(
                  '$_levelWins / 10',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  colors.onSurface.withOpacity(.10),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currentLevel == 4
                ? 'maximum_level'.tr()
                : 'wins_to_next_level'.tr(
                    args: [
                      '${10 - _levelWins}',
                    ],
                  ),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomMatchCard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              AppColors.primary.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(.15),
                  AppColors.primary.withOpacity(.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'random_match'.tr(),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'random_match_description'.tr(
              args: [
                _levels[_currentLevel].tr(),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _infoChip(
                Icons.timer_outlined,
                '3 min',
              ),
              const SizedBox(width: 8),
              _infoChip(
                Icons.quiz_outlined,
                '20 ${'questions'.tr()}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _searching
                  ? _cancelSearch
                  : _startRandomMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
              icon: Icon(
                _searching
                    ? Icons.close_rounded
                    : Icons.search_rounded,
              ),
              label: Text(
                _searching
                    ? 'cancel_search'.tr()
                    : 'find_opponent'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_searching) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'searching_opponent'.tr(),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: colors.onSurface.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsHeader() {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'play_with_friend'.tr(),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'same_level_friend'.tr(),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                AppColors.primary.withOpacity(.09),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.people_alt_outlined,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFriends() {
    final colors =
        Theme.of(context).colorScheme;

    if (_friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color:
                  colors.onSurface.withOpacity(.35),
            ),
            const SizedBox(height: 10),
            Text(
              'no_friends_available'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          _friends.map(_buildFriendCard).toList(),
    );
  }

  Widget _buildFriendCard(
    Map<String, dynamic> friend,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    final isOnline =
        friend['is_online'] == true;

    final level =
        (friend['current_level'] as num?)
                ?.toInt() ??
            0;

    final wins =
        (friend['level_wins'] as num?)
                ?.toInt() ??
            0;

    final safeLevel =
        level.clamp(0, _levels.length - 1);

    final sameLevel =
        level == _currentLevel;

    final canPlay =
        isOnline && sameLevel;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    AppColors.primary
                        .withOpacity(.10),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration:
                        BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  friend['username']
                      .toString(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? '${_levels[safeLevel].tr()} · $wins/10'
                      : 'offline'.tr(),
                  style: TextStyle(
                    color: isOnline
                        ? colors
                            .onSurfaceVariant
                        : colors.onSurface
                            .withOpacity(.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed:
                  canPlay &&
                          !_creatingFriendMatch
                      ? () =>
                          _playWithFriend(
                            friend,
                          )
                      : null,
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 15,
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
                'play'.tr(),
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}