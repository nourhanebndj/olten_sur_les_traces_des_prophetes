import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineQuizService {
  OnlineQuizService._();

  static final OnlineQuizService instance =
      OnlineQuizService._();

  final SupabaseClient _client =
      Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  String? get userId => currentUser?.id;

  Future<void> setOnline(bool online) async {
    final id = userId;

    if (id == null) return;

    await _client
        .from('profiles')
        .update({
          'is_online': online,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> heartbeat() async {
    final id = userId;

    if (id == null) return;

    await _client
        .from('profiles')
        .update({
          'is_online': true,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final id = userId;

    if (id == null) {
      throw Exception('Utilisateur non connecté');
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<String?> joinRandomMatch(int level) async {
    final result = await _client.rpc(
      'join_random_match',
      params: {
        'p_level': level,
      },
    );

    if (result == null) {
      return null;
    }

    return result.toString();
  }

  Future<String> createFriendMatch({
    required String friendId,
    required int level,
  }) async {
    final result = await _client.rpc(
      'create_friend_match',
      params: {
        'p_friend_id': friendId,
        'p_level': level,
      },
    );

    return result.toString();
  }

  Future<void> leaveQueue() async {
    final id = userId;

    if (id == null) return;

    await _client
        .from('matchmaking_queue')
        .delete()
        .eq('user_id', id);
  }

  Future<Map<String, dynamic>?> findActiveMatch() async {
    final id = userId;

    if (id == null) return null;

    final rows = await _client
        .from('matches')
        .select()
        .or(
          'player1_id.eq.$id,player2_id.eq.$id',
        )
        .inFilter(
          'status',
          ['playing', 'finished'],
        )
        .order(
          'created_at',
          ascending: false,
        )
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(
      rows.first,
    );
  }

  Future<Map<String, dynamic>> getMatch(
    String matchId,
  ) async {
    final data = await _client
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMatchQuestions(
    String matchId,
  ) async {
    final match = await getMatch(matchId);

    final rawIds =
        List<dynamic>.from(
      match['question_ids'] ?? [],
    );

    final ids = rawIds
        .map(
          (id) => id.toString(),
        )
        .toList();

    if (ids.isEmpty) {
      return [];
    }

    final rows = await _client
        .from('quiz_questions')
        .select()
        .inFilter('id', ids);

    final questionsById =
        <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final question =
          Map<String, dynamic>.from(row);

      questionsById[
        question['id'].toString()
      ] = question;
    }

    final result =
        <Map<String, dynamic>>[];

    for (int i = 0; i < ids.length; i++) {
      final question =
          questionsById[ids[i]];

      if (question == null) continue;

      result.add({
        ...question,
        'position': i,
      });
    }

    result.sort(
      (a, b) =>
          (a['position'] as int)
              .compareTo(
            b['position'] as int,
          ),
    );

    return result;
  }

  Future<bool> submitAnswer({
    required String matchId,
    required String questionId,
    required int answerIndex,
  }) async {
    final result = await _client.rpc(
      'submit_match_answer',
      params: {
        'p_match_id': matchId,
        'p_question_id': questionId,
        'p_answer_index': answerIndex,
      },
    );

    return result == true;
  }

  Future<Map<String, dynamic>> finishMatch(
    String matchId,
  ) async {
    final result = await _client.rpc(
      'finish_match',
      params: {
        'p_match_id': matchId,
      },
    );

    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final id = userId;

    if (id == null) {
      return [];
    }

    final rows = await _client
        .from('friendships')
        .select(
          'user_id, friend_id, status',
        )
        .eq(
          'status',
          'accepted',
        )
        .or(
          'user_id.eq.$id,friend_id.eq.$id',
        );

    final friendIds = <String>[];

    for (final row in rows) {
      final userId =
          row['user_id'].toString();

      final friendId =
          row['friend_id'].toString();

      final otherId =
          userId == id ? friendId : userId;

      if (!friendIds.contains(otherId)) {
        friendIds.add(otherId);
      }
    }

    if (friendIds.isEmpty) {
      return [];
    }

    final profiles = await _client
        .from('profiles')
        .select(
          'id, username, avatar_url, '
          'is_online, current_level, '
          'level_wins, last_seen',
        )
        .inFilter(
          'id',
          friendIds,
        );

    return profiles
        .map(
          (profile) =>
              Map<String, dynamic>.from(profile),
        )
        .toList();
  }

  RealtimeChannel watchMatch({
    required String matchId,
    required void Function(
      Map<String, dynamic>,
    ) onMatchChanged,
  }) {
    final channel =
        _client.channel(
      'match_$matchId',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onMatchChanged(
                Map<String, dynamic>.from(
                  payload.newRecord,
                ),
              );
            }
          },
        )
        .subscribe();

    return channel;
  }

  Future<void> removeChannel(
    RealtimeChannel channel,
  ) async {
    await _client.removeChannel(
      channel,
    );
  }
}