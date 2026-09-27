import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:olten_sur_les_traces_des_prophetes/data/local/database_helper.dart';

class SyncService {
  SyncService._();

  static final SyncService instance =
      SyncService._();

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  bool _isSyncing = false;

  void start() {
    if (_connectivitySubscription != null) {
      return;
    }

    _connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen((results) {
      final isOnline = results.any(
        (result) =>
            result != ConnectivityResult.none,
      );

      if (isOnline) {
        sync();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();

    _connectivitySubscription = null;
  }

  Future<bool> isOnline() async {
    final results =
        await Connectivity().checkConnectivity();

    return results.any(
      (result) =>
          result != ConnectivityResult.none,
    );
  }

  Future<void> sync() async {
    if (_isSyncing) {
      return;
    }

    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (!await isOnline()) {
      return;
    }

    _isSyncing = true;

    try {
      final userId = user.id;

      await _database.ensureQuizProgressForUser(
        userId,
      );

      await _uploadProfile(userId);

      await _downloadProfile(userId);

      await _uploadProgress(userId);

      await _downloadProgress(userId);

      await _uploadAttempts(userId);

      await _downloadAttempts(userId);
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _uploadProfile(
    String userId,
  ) async {
    final profile =
        await _database.getUserProfile(
      userId,
    );

    if (profile == null) {
      return;
    }

    await _supabase
        .from('profiles')
        .upsert(
      {
        'user_id': userId,
        'name': profile['name'] ?? '',
        'email': profile['email'] ?? '',
        'avatar': profile['avatar'] ?? 0,
        'updated_at':
            profile['updated_at'] ??
                DateTime.now()
                    .toUtc()
                    .toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<void> _downloadProfile(
    String userId,
  ) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return;
    }

    final remoteUpdated =
        response['updated_at']?.toString();

    final local =
        await _database.getUserProfile(
      userId,
    );

    if (local == null) {
      await _database.saveUserProfile(
        userId: userId,
        name: response['name']?.toString() ?? '',
        email:
            response['email']?.toString() ?? '',
        avatar:
            (response['avatar'] as int?) ?? 0,
        isGuest: false,
      );

      return;
    }

    final localUpdated =
        DateTime.tryParse(
              local['updated_at'].toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

    final parsedRemote =
        DateTime.tryParse(
              remoteUpdated ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

    if (parsedRemote.isAfter(localUpdated)) {
      await _database.saveUserProfile(
        userId: userId,
        name:
            response['name']?.toString() ?? '',
        email:
            response['email']?.toString() ?? '',
        avatar:
            (response['avatar'] as int?) ?? 0,
        isGuest: false,
      );
    }
  }

  Future<void> _uploadProgress(
    String userId,
  ) async {
    final rows =
        await _database.getPendingProgress(
      userId,
    );

    for (final row in rows) {
      final prophetId =
          row['prophet_id'].toString();

      final level =
          (row['level'] as num).toInt();

      await _supabase
          .from('quiz_progress')
          .upsert(
        {
          'user_id': userId,
          'prophet_id': prophetId,
          'level': level,
          'best_score':
              row['best_score'] ?? 0,
          'last_score':
              row['last_score'] ?? 0,
          'total_questions':
              row['total_questions'] ?? 0,
          'completed':
              (row['completed'] ?? 0) == 1,
          'unlocked':
              (row['unlocked'] ?? 0) == 1,
          'updated_at':
              row['updated_at'] ??
                  DateTime.now()
                      .toUtc()
                      .toIso8601String(),
        },
        onConflict:
            'user_id,prophet_id,level',
      );

      await _database.markProgressSynced(
        userId: userId,
        prophetId: prophetId,
        level: level,
      );
    }
  }

  Future<void> _downloadProgress(
    String userId,
  ) async {
    final response = await _supabase
        .from('quiz_progress')
        .select()
        .eq('user_id', userId);

    for (final row in response) {
      await _database.mergeRemoteProgress(
        userId: userId,
        prophetId:
            row['prophet_id'].toString(),
        level:
            (row['level'] as num).toInt(),
        bestScore:
            (row['best_score'] as num?)?.toInt() ??
                0,
        lastScore:
            (row['last_score'] as num?)?.toInt() ??
                0,
        totalQuestions:
            (row['total_questions'] as num?)
                    ?.toInt() ??
                0,
        completed:
            row['completed'] == true,
        unlocked:
            row['unlocked'] == true,
        updatedAt:
            row['updated_at'].toString(),
      );
    }
  }

  Future<void> _uploadAttempts(
    String userId,
  ) async {
    final rows =
        await _database.getPendingAttempts(
      userId,
    );

    for (final row in rows) {
      final syncId =
          row['sync_id'].toString();

      await _supabase
          .from('quiz_attempts')
          .upsert(
        {
          'sync_id': syncId,
          'user_id': userId,
          'prophet_id':
              row['prophet_id'],
          'level':
              row['level'],
          'score':
              row['score'],
          'total_questions':
              row['total'],
          'completed_at':
              row['completed_at'],
        },
        onConflict: 'sync_id',
      );

      await _database.markAttemptSynced(
        syncId,
      );
    }
  }

  Future<void> _downloadAttempts(
    String userId,
  ) async {
    final response = await _supabase
        .from('quiz_attempts')
        .select()
        .eq('user_id', userId);

    for (final row in response) {
      await _database.saveRemoteAttempt(
        syncId:
            row['sync_id'].toString(),
        userId: userId,
        prophetId:
            row['prophet_id'].toString(),
        level:
            (row['level'] as num).toInt(),
        score:
            (row['score'] as num).toInt(),
        totalQuestions:
            (row['total_questions'] as num)
                .toInt(),
        completedAt:
            row['completed_at'].toString(),
      );
    }
  }
}