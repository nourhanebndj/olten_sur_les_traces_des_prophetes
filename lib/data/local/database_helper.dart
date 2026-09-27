import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  static Database? _database;

  static const String _databaseName = 'olten.db';
  static const int _databaseVersion = 7;

  static const int questionsPerLevel = 10;
  static const int onlineGameDurationSeconds = 180;

  final Uuid _uuid = const Uuid();

  String? _cachedGuestId;

  List<Map<String, dynamic>>? _cachedProphets;

  Future<Database> get database async {
    final existing = _database;

    if (existing != null) {
      return existing;
    }

    final db = await _initDatabase();

    _database = db;

    return db;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();

    final dbPath = join(
      databasesPath,
      _databaseName,
    );

    return openDatabase(
      dbPath,
      version: _databaseVersion,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await _createBaseTables(db);
    await _createSyncTables(db);
    await _createSettingsTable(db);
    await _createMultiplayerTables(db);
  }

  Future<void> _createBaseTables(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE prophets (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_fr TEXT NOT NULL,
        image TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        summary_ar TEXT NOT NULL,
        summary_en TEXT NOT NULL,
        summary_fr TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prophet_id TEXT NOT NULL,
        audience TEXT NOT NULL,
        source_id INTEGER NOT NULL,
        title_ar TEXT NOT NULL,
        title_en TEXT NOT NULL,
        title_fr TEXT NOT NULL,
        content_ar TEXT NOT NULL,
        content_en TEXT NOT NULL,
        content_fr TEXT NOT NULL,

        FOREIGN KEY (prophet_id)
          REFERENCES prophets(id)
          ON DELETE CASCADE,

        UNIQUE (
          prophet_id,
          audience,
          source_id
        )
      )
    ''');

    await db.execute('''
      CREATE TABLE quran_references (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER NOT NULL,
        reference TEXT NOT NULL,

        FOREIGN KEY (story_id)
          REFERENCES stories(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER NOT NULL,
        language TEXT NOT NULL,
        content TEXT NOT NULL,

        FOREIGN KEY (story_id)
          REFERENCES stories(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        id TEXT PRIMARY KEY,
        prophet_id TEXT NOT NULL,
        level INTEGER NOT NULL,
        question_order INTEGER NOT NULL,
        question_ar TEXT NOT NULL,
        question_fr TEXT NOT NULL,
        options_ar TEXT NOT NULL,
        options_fr TEXT NOT NULL,
        correct INTEGER NOT NULL,
        explanation_ar TEXT NOT NULL,
        explanation_fr TEXT NOT NULL,

        FOREIGN KEY (prophet_id)
          REFERENCES prophets(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_stories_prophet
      ON stories(prophet_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_stories_prophet_audience
      ON stories(prophet_id, audience)
    ''');

    await db.execute('''
      CREATE INDEX idx_stories_audience
      ON stories(audience)
    ''');

    await db.execute('''
      CREATE INDEX idx_stories_source
      ON stories(prophet_id, audience, source_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quran_story
      ON quran_references(story_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_lessons_story
      ON lessons(story_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_lessons_story_language
      ON lessons(story_id, language)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_questions_prophet
      ON quiz_questions(prophet_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_questions_level
      ON quiz_questions(prophet_id, level)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_questions_random
      ON quiz_questions(level, prophet_id)
    ''');
  }

  Future<void> _createSyncTables(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE local_identity (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        guest_user_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profiles (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        avatar INTEGER NOT NULL DEFAULT 0,
        is_guest INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        prophet_id TEXT NOT NULL,
        level INTEGER NOT NULL,
        best_score INTEGER NOT NULL DEFAULT 0,
        last_score INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        unlocked INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (prophet_id)
          REFERENCES prophets(id)
          ON DELETE CASCADE,

        UNIQUE (
          user_id,
          prophet_id,
          level
        )
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL,
        prophet_id TEXT NOT NULL,
        level INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (prophet_id)
          REFERENCES prophets(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_progress_user
      ON quiz_progress(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_progress_prophet
      ON quiz_progress(user_id, prophet_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_progress_level
      ON quiz_progress(user_id, prophet_id, level)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_attempts_user
      ON quiz_attempts(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_attempts_prophet
      ON quiz_attempts(user_id, prophet_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_quiz_attempts_level
      ON quiz_attempts(user_id, prophet_id, level)
    ''');

    final guestId = _uuid.v4();

    await db.insert(
      'local_identity',
      {
        'id': 1,
        'guest_user_id': guestId,
      },
    );

    _cachedGuestId = guestId;
  }

  Future<void> _createMultiplayerTables(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE online_quiz_progress (
        user_id TEXT PRIMARY KEY,
        total_wins INTEGER NOT NULL DEFAULT 0,
        total_losses INTEGER NOT NULL DEFAULT 0,
        total_draws INTEGER NOT NULL DEFAULT 0,
        current_level INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE online_match_cache (
        match_id TEXT PRIMARY KEY,
        mode TEXT NOT NULL,
        player1_id TEXT,
        player2_id TEXT,
        status TEXT NOT NULL,
        private_code TEXT,
        started_at TEXT,
        ends_at TEXT,
        winner_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE online_match_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        question_order INTEGER NOT NULL,

        UNIQUE (
          match_id,
          question_id
        )
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_online_progress_level
      ON online_quiz_progress(current_level)
    ''');

    await db.execute('''
      CREATE INDEX idx_online_match_status
      ON online_match_cache(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_online_match_players
      ON online_match_cache(player1_id, player2_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_online_match_questions_match
      ON online_match_questions(match_id)
    ''');
  }

  Future<void> _createSettingsTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(prophets)',
      );

      final hasImage = columns.any(
        (column) => column['name'] == 'image',
      );

      if (!hasImage) {
        await db.execute('''
          ALTER TABLE prophets
          ADD COLUMN image TEXT NOT NULL DEFAULT ''
        ''');
      }
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_questions (
          id TEXT PRIMARY KEY,
          prophet_id TEXT NOT NULL,
          level INTEGER NOT NULL,
          question_order INTEGER NOT NULL,
          question_ar TEXT NOT NULL,
          question_fr TEXT NOT NULL,
          options_ar TEXT NOT NULL,
          options_fr TEXT NOT NULL,
          correct INTEGER NOT NULL,
          explanation_ar TEXT NOT NULL,
          explanation_fr TEXT NOT NULL,

          FOREIGN KEY (prophet_id)
            REFERENCES prophets(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prophet_id TEXT NOT NULL,
          level INTEGER NOT NULL,
          best_score INTEGER NOT NULL DEFAULT 0,
          last_score INTEGER NOT NULL DEFAULT 0,
          total_questions INTEGER NOT NULL DEFAULT 0,
          completed INTEGER NOT NULL DEFAULT 0,
          unlocked INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (prophet_id)
            REFERENCES prophets(id)
            ON DELETE CASCADE,

          UNIQUE (
            prophet_id,
            level
          )
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prophet_id TEXT NOT NULL,
          level INTEGER NOT NULL,
          score INTEGER NOT NULL,
          total INTEGER NOT NULL,
          completed_at TEXT NOT NULL,

          FOREIGN KEY (prophet_id)
            REFERENCES prophets(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_questions_prophet
        ON quiz_questions(prophet_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_questions_level
        ON quiz_questions(prophet_id, level)
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_identity (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          guest_user_id TEXT NOT NULL
        )
      ''');

      final identity = await db.query(
        'local_identity',
        limit: 1,
      );

      if (identity.isEmpty) {
        final guestId = _uuid.v4();

        await db.insert(
          'local_identity',
          {
            'id': 1,
            'guest_user_id': guestId,
          },
        );

        _cachedGuestId = guestId;
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          user_id TEXT PRIMARY KEY,
          name TEXT NOT NULL DEFAULT '',
          email TEXT NOT NULL DEFAULT '',
          avatar INTEGER NOT NULL DEFAULT 0,
          is_guest INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await _migrateQuizTablesToUserScoped(db);
    }

    if (oldVersion < 6) {
      await _createSettingsTable(db);
    }

    if (oldVersion < 7) {
      await _createMultiplayerTables(db);
    }
  }

  Future<void> _migrateQuizTablesToUserScoped(
    Database db,
  ) async {
    final identity = await db.query(
      'local_identity',
      limit: 1,
    );

    String guestId;

    if (identity.isEmpty) {
      guestId = _uuid.v4();

      await db.insert(
        'local_identity',
        {
          'id': 1,
          'guest_user_id': guestId,
        },
      );

      _cachedGuestId = guestId;
    } else {
      guestId =
          identity.first['guest_user_id'].toString();

      _cachedGuestId = guestId;
    }

    await db.transaction((txn) async {
      final oldProgressExists =
          await _tableExists(
        txn,
        'quiz_progress',
      );

      if (oldProgressExists) {
        final columns = await txn.rawQuery(
          'PRAGMA table_info(quiz_progress)',
        );

        final hasUserId = columns.any(
          (column) => column['name'] == 'user_id',
        );

        if (!hasUserId) {
          final oldRows =
              await txn.query('quiz_progress');

          await txn.execute('''
            CREATE TABLE quiz_progress_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              prophet_id TEXT NOT NULL,
              level INTEGER NOT NULL,
              best_score INTEGER NOT NULL DEFAULT 0,
              last_score INTEGER NOT NULL DEFAULT 0,
              total_questions INTEGER NOT NULL DEFAULT 0,
              completed INTEGER NOT NULL DEFAULT 0,
              unlocked INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL,
              pending_sync INTEGER NOT NULL DEFAULT 0,

              FOREIGN KEY (prophet_id)
                REFERENCES prophets(id)
                ON DELETE CASCADE,

              UNIQUE (
                user_id,
                prophet_id,
                level
              )
            )
          ''');

          final batch = txn.batch();

          final now = DateTime.now()
              .toUtc()
              .toIso8601String();

          for (final row in oldRows) {
            batch.insert(
              'quiz_progress_new',
              {
                'user_id': guestId,
                'prophet_id':
                    row['prophet_id'],
                'level': row['level'],
                'best_score':
                    row['best_score'] ?? 0,
                'last_score':
                    row['last_score'] ?? 0,
                'total_questions':
                    row['total_questions'] ?? 0,
                'completed':
                    row['completed'] ?? 0,
                'unlocked':
                    row['unlocked'] ?? 0,
                'updated_at': now,
                'pending_sync': 0,
              },
            );
          }

          await batch.commit(
            noResult: true,
          );

          await txn.execute(
            'DROP TABLE quiz_progress',
          );

          await txn.execute(
            'ALTER TABLE quiz_progress_new '
            'RENAME TO quiz_progress',
          );
        }
      }

      final oldAttemptsExists =
          await _tableExists(
        txn,
        'quiz_attempts',
      );

      if (oldAttemptsExists) {
        final columns = await txn.rawQuery(
          'PRAGMA table_info(quiz_attempts)',
        );

        final hasUserId = columns.any(
          (column) => column['name'] == 'user_id',
        );

        if (!hasUserId) {
          final oldAttempts =
              await txn.query('quiz_attempts');

          await txn.execute('''
            CREATE TABLE quiz_attempts_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sync_id TEXT NOT NULL UNIQUE,
              user_id TEXT NOT NULL,
              prophet_id TEXT NOT NULL,
              level INTEGER NOT NULL,
              score INTEGER NOT NULL,
              total INTEGER NOT NULL,
              completed_at TEXT NOT NULL,
              pending_sync INTEGER NOT NULL DEFAULT 0,

              FOREIGN KEY (prophet_id)
                REFERENCES prophets(id)
                ON DELETE CASCADE
            )
          ''');

          final batch = txn.batch();

          for (final row in oldAttempts) {
            batch.insert(
              'quiz_attempts_new',
              {
                'sync_id': _uuid.v4(),
                'user_id': guestId,
                'prophet_id':
                    row['prophet_id'],
                'level': row['level'],
                'score': row['score'],
                'total': row['total'],
                'completed_at':
                    row['completed_at'],
                'pending_sync': 0,
              },
            );
          }

          await batch.commit(
            noResult: true,
          );

          await txn.execute(
            'DROP TABLE quiz_attempts',
          );

          await txn.execute(
            'ALTER TABLE quiz_attempts_new '
            'RENAME TO quiz_attempts',
          );
        }
      }

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_progress_user
        ON quiz_progress(user_id)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_progress_prophet
        ON quiz_progress(user_id, prophet_id)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_progress_level
        ON quiz_progress(user_id, prophet_id, level)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user
        ON quiz_attempts(user_id)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_prophet
        ON quiz_attempts(user_id, prophet_id)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_level
        ON quiz_attempts(user_id, prophet_id, level)
      ''');
    });
  }

  Future<bool> _tableExists(
    DatabaseExecutor db,
    String table,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = ?
      ''',
      [table],
    );

    return result.isNotEmpty;
  }

  Future<String> getGuestUserId() async {
    final cached = _cachedGuestId;

    if (cached != null) {
      return cached;
    }

    final db = await database;

    final result = await db.query(
      'local_identity',
      columns: ['guest_user_id'],
      where: 'id = 1',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final id =
          result.first['guest_user_id'].toString();

      _cachedGuestId = id;

      return id;
    }

    final guestId = _uuid.v4();

    await db.insert(
      'local_identity',
      {
        'id': 1,
        'guest_user_id': guestId,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );

    _cachedGuestId = guestId;

    return guestId;
  }

  Future<String> get guestUserId async {
    return getGuestUserId();
  }

  bool _isGuestUserId(
    String userId,
  ) {
    return userId.isNotEmpty &&
        userId == _cachedGuestId;
  }

  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    int avatar = 0,
    bool isGuest = false,
  }) async {
    final db = await database;

    await db.insert(
      'user_profiles',
      {
        'user_id': userId,
        'name': name.trim(),
        'email': email.trim(),
        'avatar': avatar,
        'is_guest': isGuest ? 1 : 0,
        'updated_at':
            DateTime.now()
                .toUtc()
                .toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(
    String userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    return result.isEmpty
        ? null
        : result.first;
  }

  Future<void> updateUserAvatar({
    required String userId,
    required int avatar,
  }) async {
    final db = await database;

    await db.update(
      'user_profiles',
      {
        'avatar': avatar,
        'updated_at':
            DateTime.now()
                .toUtc()
                .toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> ensureQuizProgressForUser(
    String userId,
  ) async {
    final db = await database;

    final existing = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM quiz_progress
      WHERE user_id = ?
      ''',
      [userId],
    );

    final existingCount =
        Sqflite.firstIntValue(existing) ?? 0;

    if (existingCount > 0) {
      return;
    }

    final levels = await db.rawQuery(
      '''
      SELECT
        prophet_id,
        level,
        COUNT(*) AS total
      FROM quiz_questions
      GROUP BY prophet_id, level
      ORDER BY prophet_id, level
      ''',
    );

    if (levels.isEmpty) {
      return;
    }

    final now = DateTime.now()
        .toUtc()
        .toIso8601String();

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final row in levels) {
        final level =
            (row['level'] as num).toInt();

        batch.insert(
          'quiz_progress',
          {
            'user_id': userId,
            'prophet_id':
                row['prophet_id'],
            'level': level,
            'best_score': 0,
            'last_score': 0,
            'total_questions':
                (row['total'] as num).toInt(),
            'completed': 0,
            'unlocked':
                level == 1 ? 1 : 0,
            'updated_at': now,
            'pending_sync': 0,
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(
        noResult: true,
      );
    });
  }

  Future<void> initializeProphetStories() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT EXISTS(
        SELECT 1
        FROM prophets
        LIMIT 1
      ) AS exists_value
      ''',
    );

    final exists =
        Sqflite.firstIntValue(
              result,
            ) ??
            0;

    if (exists == 1) {
      return;
    }

    await importProphetStories();
  }

  Future<void> importProphetStories() async {
    final db = await database;

    final indexJson =
        await rootBundle.loadString(
      'assets/data/prophet_stories/index.json',
    );

    final decoded =
        jsonDecode(indexJson);

    if (decoded is! List) {
      return;
    }

    final prophets =
        List<dynamic>.from(decoded);

    final files = await Future.wait(
      prophets.map(
        (item) async {
          final prophet =
              Map<String, dynamic>.from(item);

          final prophetId =
              prophet['id'].toString();

          final path =
              'assets/data/prophet_stories/'
              '$prophetId.json';

          try {
            final json =
                await rootBundle.loadString(
              path,
            );

            return (
              prophet: prophet,
              data: jsonDecode(json),
            );
          } catch (_) {
            return (
              prophet: prophet,
              data: null,
            );
          }
        },
      ),
    );

    await db.transaction((txn) async {
      final prophetBatch = txn.batch();

      for (final file in files) {
        final prophet = file.prophet;

        prophetBatch.insert(
          'prophets',
          {
            'id':
                prophet['id'].toString(),
            'name_ar':
                prophet['nameAr'] ?? '',
            'name_en':
                prophet['nameEn'] ?? '',
            'name_fr':
                prophet['nameFr'] ?? '',
            'image':
                prophet['image'] ?? '',
            'display_order':
                prophet['order'] ?? 0,
            'summary_ar':
                prophet['summaryAr'] ?? '',
            'summary_en':
                prophet['summaryEn'] ?? '',
            'summary_fr':
                prophet['summaryFr'] ?? '',
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }

      await prophetBatch.commit(
        noResult: true,
      );

      for (final file in files) {
        final data = file.data;

        if (data is! Map) {
          continue;
        }

        final prophetId =
            file.prophet['id'].toString();

        await _importAudienceStories(
          txn,
          prophetId,
          'adult',
          data['adult'],
        );

        await _importAudienceStories(
          txn,
          prophetId,
          'kids',
          data['kids'],
        );
      }
    });

    _cachedProphets = null;
  }

  Future<void> _importAudienceStories(
    DatabaseExecutor db,
    String prophetId,
    String audience,
    dynamic storiesData,
  ) async {
    if (storiesData is! List ||
        storiesData.isEmpty) {
      return;
    }

    final references = <Map<String, dynamic>>[];
    final lessons = <Map<String, dynamic>>[];

    for (final item in storiesData) {
      if (item is! Map) {
        continue;
      }

      final story =
          Map<String, dynamic>.from(item);

      final sourceId =
          (story['id'] as num).toInt();

      final existing =
          await db.query(
        'stories',
        columns: ['id'],
        where:
            'prophet_id = ? '
            'AND audience = ? '
            'AND source_id = ?',
        whereArgs: [
          prophetId,
          audience,
          sourceId,
        ],
        limit: 1,
      );

      int storyId;

      if (existing.isNotEmpty) {
        storyId =
            (existing.first['id'] as num)
                .toInt();
      } else {
        storyId = await db.insert(
          'stories',
          {
            'prophet_id': prophetId,
            'audience': audience,
            'source_id': sourceId,
            'title_ar':
                story['titleAr'] ?? '',
            'title_en':
                story['titleEn'] ?? '',
            'title_fr':
                story['titleFr'] ?? '',
            'content_ar':
                story['contentAr'] ?? '',
            'content_en':
                story['contentEn'] ?? '',
            'content_fr':
                story['contentFr'] ?? '',
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }

      final quranReferences =
          story['quranReferences'];

      if (quranReferences is List) {
        for (final reference
            in quranReferences) {
          references.add({
            'story_id': storyId,
            'reference':
                reference.toString(),
          });
        }
      }

      final lessonsAr =
          story['lessonsAr'];

      if (lessonsAr is List) {
        for (final lesson in lessonsAr) {
          lessons.add({
            'story_id': storyId,
            'language': 'ar',
            'content':
                lesson.toString(),
          });
        }
      }

      final lessonsEn =
          story['lessonsEn'];

      if (lessonsEn is List) {
        for (final lesson in lessonsEn) {
          lessons.add({
            'story_id': storyId,
            'language': 'en',
            'content':
                lesson.toString(),
          });
        }
      }

      final lessonsFr =
          story['lessonsFr'];

      if (lessonsFr is List) {
        for (final lesson in lessonsFr) {
          lessons.add({
            'story_id': storyId,
            'language': 'fr',
            'content':
                lesson.toString(),
          });
        }
      }
    }

    if (references.isNotEmpty) {
      final batch = db.batch();

      for (final reference in references) {
        batch.insert(
          'quran_references',
          reference,
        );
      }

      await batch.commit(
        noResult: true,
      );
    }

    if (lessons.isNotEmpty) {
      final batch = db.batch();

      for (final lesson in lessons) {
        batch.insert(
          'lessons',
          lesson,
        );
      }

      await batch.commit(
        noResult: true,
      );
    }
  }

  Future<List<Map<String, dynamic>>>
      getProphets() async {
    final cached = _cachedProphets;

    if (cached != null) {
      return List<Map<String, dynamic>>.from(
        cached,
      );
    }

    final db = await database;

    final result = await db.query(
      'prophets',
      orderBy: 'display_order ASC',
    );

    _cachedProphets =
        List<Map<String, dynamic>>.from(
      result,
    );

    return result;
  }

  Future<Map<String, dynamic>?> getProphet(
    String id,
  ) async {
    final db = await database;

    final result = await db.query(
      'prophets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty
        ? null
        : result.first;
  }

  Future<List<Map<String, dynamic>>> getStories(
    String prophetId, {
    String audience = 'adult',
  }) async {
    final db = await database;

    return db.query(
      'stories',
      where:
          'prophet_id = ? AND audience = ?',
      whereArgs: [
        prophetId,
        audience,
      ],
      orderBy: 'source_id ASC',
    );
  }

  Future<Map<String, dynamic>?> getStory(
    int storyId,
  ) async {
    final db = await database;

    final result = await db.query(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
      limit: 1,
    );

    return result.isEmpty
        ? null
        : result.first;
  }

  Future<List<String>> getQuranReferences(
    int storyId,
  ) async {
    final db = await database;

    final result = await db.query(
      'quran_references',
      columns: ['reference'],
      where: 'story_id = ?',
      whereArgs: [storyId],
      orderBy: 'id ASC',
    );

    return result
        .map(
          (row) =>
              row['reference'].toString(),
        )
        .toList();
  }

  Future<List<String>> getLessons(
    int storyId,
    String language,
  ) async {
    final db = await database;

    final result = await db.query(
      'lessons',
      columns: ['content'],
      where:
          'story_id = ? AND language = ?',
      whereArgs: [
        storyId,
        language,
      ],
      orderBy: 'id ASC',
    );

    return result
        .map(
          (row) =>
              row['content'].toString(),
        )
        .toList();
  }

  Future<void> initializeQuizzes() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT EXISTS(
        SELECT 1
        FROM quiz_questions
        LIMIT 1
      ) AS exists_value
      ''',
    );

    final exists =
        Sqflite.firstIntValue(
              result,
            ) ??
            0;

    final guestId =
        await getGuestUserId();

    if (exists == 0) {
      await importQuizzes();
      return;
    }

    await ensureQuizProgressForUser(
      guestId,
    );
  }

  Future<void> importQuizzes() async {
    final db = await database;

    final indexJson =
        await rootBundle.loadString(
      'assets/data/prophet_stories/index.json',
    );

    final decoded =
        jsonDecode(indexJson);

    if (decoded is! List) {
      return;
    }

    final prophets =
        List<dynamic>.from(decoded);

    final files = await Future.wait(
      prophets.map(
        (item) async {
          final prophet =
              Map<String, dynamic>.from(item);

          final prophetId =
              prophet['id'].toString();

          final path =
              'assets/data/quizzes/'
              '$prophetId.json';

          try {
            final json =
                await rootBundle.loadString(
              path,
            );

            return (
              prophetId: prophetId,
              data: jsonDecode(json),
            );
          } catch (_) {
            return (
              prophetId: prophetId,
              data: null,
            );
          }
        },
      ),
    );

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final file in files) {
        if (file.data is! List) {
          continue;
        }

        final questions =
            List<dynamic>.from(
          file.data,
        );

        for (int i = 0;
            i < questions.length;
            i++) {
          final raw =
              questions[i];

          if (raw is! Map) {
            continue;
          }

          final question =
              Map<String, dynamic>.from(
            raw,
          );

          final id =
              question['id']?.toString();

          if (id == null ||
              id.isEmpty) {
            continue;
          }

          final level =
              (i ~/ questionsPerLevel) + 1;

          batch.insert(
            'quiz_questions',
            {
              'id': id,
              'prophet_id':
                  file.prophetId,
              'level': level,
              'question_order': i + 1,
              'question_ar':
                  question['question_ar'] ??
                      '',
              'question_fr':
                  question['question_fr'] ??
                      '',
              'options_ar': jsonEncode(
                List<dynamic>.from(
                  question['options_ar'] ??
                      [],
                ),
              ),
              'options_fr': jsonEncode(
                List<dynamic>.from(
                  question['options_fr'] ??
                      [],
                ),
              ),
              'correct':
                  question['correct'] ?? 0,
              'explanation_ar':
                  question[
                          'explanation_ar'] ??
                      '',
              'explanation_fr':
                  question[
                          'explanation_fr'] ??
                      '',
            },
            conflictAlgorithm:
                ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(
        noResult: true,
      );
    });

    final guestId =
        await getGuestUserId();

    await ensureQuizProgressForUser(
      guestId,
    );
  }

  Future<List<Map<String, dynamic>>> getQuizLevels(
    String prophetId, {
    String? userId,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    await ensureQuizProgressForUser(
      effectiveUserId,
    );

    return db.query(
      'quiz_progress',
      where:
          'user_id = ? AND prophet_id = ?',
      whereArgs: [
        effectiveUserId,
        prophetId,
      ],
      orderBy: 'level ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getQuizQuestions(
    String prophetId,
    int level,
  ) async {
    final db = await database;

    return db.query(
      'quiz_questions',
      columns: [
        'id',
        'prophet_id',
        'level',
        'question_order',
        'question_ar',
        'question_fr',
        'options_ar',
        'options_fr',
        'correct',
        'explanation_ar',
        'explanation_fr',
      ],
      where:
          'prophet_id = ? AND level = ?',
      whereArgs: [
        prophetId,
        level,
      ],
      orderBy: 'question_order ASC',
    );
  }

  Future<Map<String, dynamic>?> getQuizLevel(
    String prophetId,
    int level, {
    String? userId,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    await ensureQuizProgressForUser(
      effectiveUserId,
    );

    final result = await db.query(
      'quiz_progress',
      where:
          'user_id = ? '
          'AND prophet_id = ? '
          'AND level = ?',
      whereArgs: [
        effectiveUserId,
        prophetId,
        level,
      ],
      limit: 1,
    );

    return result.isEmpty
        ? null
        : result.first;
  }

  Future<bool> isQuizLevelUnlocked(
    String prophetId,
    int level, {
    String? userId,
  }) async {
    final progress =
        await getQuizLevel(
      prophetId,
      level,
      userId: userId,
    );

    return progress?['unlocked'] == 1;
  }

  Future<void> saveQuizResult({
    String? userId,
    required String prophetId,
    required int level,
    required int score,
    required int total,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    await ensureQuizProgressForUser(
      effectiveUserId,
    );

    final now =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    final isGuest =
        _isGuestUserId(
      effectiveUserId,
    );

    await db.transaction((txn) async {
      final current =
          await txn.query(
        'quiz_progress',
        columns: [
          'best_score',
        ],
        where:
            'user_id = ? '
            'AND prophet_id = ? '
            'AND level = ?',
        whereArgs: [
          effectiveUserId,
          prophetId,
          level,
        ],
        limit: 1,
      );

      final currentBest =
          current.isEmpty
              ? 0
              : ((current.first[
                          'best_score']
                      as int?) ??
                  0);

      final bestScore =
          score > currentBest
              ? score
              : currentBest;

      final completed =
          score >= total;

      await txn.insert(
        'quiz_attempts',
        {
          'sync_id': _uuid.v4(),
          'user_id': effectiveUserId,
          'prophet_id': prophetId,
          'level': level,
          'score': score,
          'total': total,
          'completed_at': now,
          'pending_sync':
              isGuest ? 0 : 1,
        },
      );

      await txn.update(
        'quiz_progress',
        {
          'best_score': bestScore,
          'last_score': score,
          'total_questions': total,
          'completed':
              completed ? 1 : 0,
          'unlocked': 1,
          'updated_at': now,
          'pending_sync':
              isGuest ? 0 : 1,
        },
        where:
            'user_id = ? '
            'AND prophet_id = ? '
            'AND level = ?',
        whereArgs: [
          effectiveUserId,
          prophetId,
          level,
        ],
      );

      if (completed) {
        await txn.update(
          'quiz_progress',
          {
            'unlocked': 1,
            'updated_at': now,
            'pending_sync':
                isGuest ? 0 : 1,
          },
          where:
              'user_id = ? '
              'AND prophet_id = ? '
              'AND level = ?',
          whereArgs: [
            effectiveUserId,
            prophetId,
            level + 1,
          ],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getQuizAttempts(
    String prophetId,
    int level, {
    String? userId,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    return db.query(
      'quiz_attempts',
      where:
          'user_id = ? '
          'AND prophet_id = ? '
          'AND level = ?',
      whereArgs: [
        effectiveUserId,
        prophetId,
        level,
      ],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>> getQuizSummary(
    String prophetId, {
    String? userId,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    await ensureQuizProgressForUser(
      effectiveUserId,
    );

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_levels,
        SUM(
          CASE
            WHEN completed = 1 THEN 1
            ELSE 0
          END
        ) AS completed_levels,
        COALESCE(
          SUM(total_questions),
          0
        ) AS answered_questions
      FROM quiz_progress
      WHERE user_id = ?
      AND prophet_id = ?
      ''',
      [
        effectiveUserId,
        prophetId,
      ],
    );

    final questionsResult =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM quiz_questions
      WHERE prophet_id = ?
      ''',
      [prophetId],
    );

    final row = result.first;

    final totalQuestions =
        Sqflite.firstIntValue(
              questionsResult,
            ) ??
            0;

    final answered =
        (row['answered_questions']
                as int?) ??
            0;

    return {
      'totalLevels':
          (row['total_levels']
                  as int?) ??
              0,
      'completedLevels':
          (row['completed_levels']
                  as int?) ??
              0,
      'totalQuestions':
          totalQuestions,
      'answeredQuestions':
          answered > totalQuestions
              ? totalQuestions
              : answered,
    };
  }

  Future<List<Map<String, dynamic>>>
      getRandomOnlineQuestions({
    int limit = 100,
  }) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT *
      FROM quiz_questions
      ORDER BY RANDOM()
      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>>
      getRandomOnlineQuestionsFromAllProphets({
    int limit = 100,
  }) async {
    return getRandomOnlineQuestions(
      limit: limit,
    );
  }

  Future<Map<String, dynamic>>
      getOnlineProgress(
    String userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'online_quiz_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    final now =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    final row = {
      'user_id': userId,
      'total_wins': 0,
      'total_losses': 0,
      'total_draws': 0,
      'current_level': 1,
      'updated_at': now,
      'pending_sync': 0,
    };

    await db.insert(
      'online_quiz_progress',
      row,
      conflictAlgorithm:
          ConflictAlgorithm.ignore,
    );

    return row;
  }

  Future<void> saveOnlineResult({
    required String userId,
    required String result,
  }) async {
    final db = await database;

    final progress =
        await getOnlineProgress(
      userId,
    );

    int wins =
        (progress['total_wins'] as int?) ??
            0;

    int losses =
        (progress['total_losses'] as int?) ??
            0;

    int draws =
        (progress['total_draws'] as int?) ??
            0;

    switch (result) {
      case 'win':
        wins++;
        break;

      case 'loss':
        losses++;
        break;

      case 'draw':
        draws++;
        break;
    }

    final level =
        getOnlineLevelFromWins(wins);

    await db.insert(
      'online_quiz_progress',
      {
        'user_id': userId,
        'total_wins': wins,
        'total_losses': losses,
        'total_draws': draws,
        'current_level': level,
        'updated_at':
            DateTime.now()
                .toUtc()
                .toIso8601String(),
        'pending_sync':
            _isGuestUserId(userId)
                ? 0
                : 1,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  int getOnlineLevelFromWins(
    int wins,
  ) {
    if (wins >= 100) {
      return 5;
    }

    if (wins >= 60) {
      return 4;
    }

    if (wins >= 30) {
      return 3;
    }

    if (wins >= 10) {
      return 2;
    }

    return 1;
  }

  String getOnlineLevelName(
    int wins,
  ) {
    if (wins >= 100) {
      return 'Maître';
    }

    if (wins >= 60) {
      return 'Expert';
    }

    if (wins >= 30) {
      return 'Avancé';
    }

    if (wins >= 10) {
      return 'Intermédiaire';
    }

    return 'Débutant';
  }

  int getNextOnlineLevelWins(
    int wins,
  ) {
    if (wins < 10) {
      return 10;
    }

    if (wins < 30) {
      return 30;
    }

    if (wins < 60) {
      return 60;
    }

    if (wins < 100) {
      return 100;
    }

    return 100;
  }

  Future<void> cacheOnlineMatch({
    required String matchId,
    required String mode,
    String? player1Id,
    String? player2Id,
    required String status,
    String? privateCode,
    String? startedAt,
    String? endsAt,
    String? winnerId,
  }) async {
    final db = await database;

    await db.insert(
      'online_match_cache',
      {
        'match_id': matchId,
        'mode': mode,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'status': status,
        'private_code': privateCode,
        'started_at': startedAt,
        'ends_at': endsAt,
        'winner_id': winnerId,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheOnlineMatchQuestions({
    required String matchId,
    required List<String> questionIds,
  }) async {
    if (questionIds.isEmpty) {
      return;
    }

    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (int i = 0;
          i < questionIds.length;
          i++) {
        batch.insert(
          'online_match_questions',
          {
            'match_id': matchId,
            'question_id':
                questionIds[i],
            'question_order': i + 1,
          },
          conflictAlgorithm:
              ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(
        noResult: true,
      );
    });
  }

  Future<List<Map<String, dynamic>>>
      getCachedMatchQuestions(
    String matchId,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT q.*
      FROM online_match_questions mq
      INNER JOIN quiz_questions q
        ON q.id = mq.question_id
      WHERE mq.match_id = ?
      ORDER BY mq.question_order ASC
      ''',
      [matchId],
    );
  }

  Future<List<Map<String, dynamic>>>
      getPendingProgress(
    String userId,
  ) async {
    final db = await database;

    return db.query(
      'quiz_progress',
      where:
          'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
    );
  }

  Future<void> markProgressSynced({
    required String userId,
    required String prophetId,
    required int level,
  }) async {
    final db = await database;

    await db.update(
      'quiz_progress',
      {
        'pending_sync': 0,
      },
      where:
          'user_id = ? '
          'AND prophet_id = ? '
          'AND level = ?',
      whereArgs: [
        userId,
        prophetId,
        level,
      ],
    );
  }

  Future<List<Map<String, dynamic>>>
      getPendingAttempts(
    String userId,
  ) async {
    final db = await database;

    return db.query(
      'quiz_attempts',
      where:
          'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<void> markAttemptSynced(
    String syncId,
  ) async {
    final db = await database;

    await db.update(
      'quiz_attempts',
      {
        'pending_sync': 0,
      },
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
  }

  Future<void> saveRemoteAttempt({
    required String syncId,
    required String userId,
    required String prophetId,
    required int level,
    required int score,
    required int totalQuestions,
    required String completedAt,
  }) async {
    final db = await database;

    await db.insert(
      'quiz_attempts',
      {
        'sync_id': syncId,
        'user_id': userId,
        'prophet_id': prophetId,
        'level': level,
        'score': score,
        'total': totalQuestions,
        'completed_at': completedAt,
        'pending_sync': 0,
      },
      conflictAlgorithm:
          ConflictAlgorithm.ignore,
    );
  }

  Future<void> mergeRemoteProgress({
    required String userId,
    required String prophetId,
    required int level,
    required int bestScore,
    required int lastScore,
    required int totalQuestions,
    required bool completed,
    required bool unlocked,
    required String updatedAt,
  }) async {
    final db = await database;

    final local = await db.query(
      'quiz_progress',
      where:
          'user_id = ? '
          'AND prophet_id = ? '
          'AND level = ?',
      whereArgs: [
        userId,
        prophetId,
        level,
      ],
      limit: 1,
    );

    if (local.isEmpty) {
      await db.insert(
        'quiz_progress',
        {
          'user_id': userId,
          'prophet_id': prophetId,
          'level': level,
          'best_score': bestScore,
          'last_score': lastScore,
          'total_questions':
              totalQuestions,
          'completed':
              completed ? 1 : 0,
          'unlocked':
              unlocked ? 1 : 0,
          'updated_at': updatedAt,
          'pending_sync': 0,
        },
        conflictAlgorithm:
            ConflictAlgorithm.replace,
      );

      return;
    }

    final localRow = local.first;

    final localUpdated =
        DateTime.tryParse(
              localRow['updated_at']
                  .toString(),
            ) ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    final remoteUpdated =
        DateTime.tryParse(
              updatedAt,
            ) ??
            DateTime
                .fromMillisecondsSinceEpoch(
              0,
            );

    final localBest =
        (localRow['best_score']
                as int?) ??
            0;

    final mergedBest =
        localBest > bestScore
            ? localBest
            : bestScore;

    final mergedCompleted =
        localRow['completed'] == 1 ||
            completed;

    final mergedUnlocked =
        localRow['unlocked'] == 1 ||
            unlocked;

    if (localRow['pending_sync'] == 1) {
      await db.update(
        'quiz_progress',
        {
          'best_score': mergedBest,
          'completed':
              mergedCompleted ? 1 : 0,
          'unlocked':
              mergedUnlocked ? 1 : 0,
        },
        where:
            'user_id = ? '
            'AND prophet_id = ? '
            'AND level = ?',
        whereArgs: [
          userId,
          prophetId,
          level,
        ],
      );

      return;
    }

    if (remoteUpdated
            .isAfter(localUpdated) ||
        remoteUpdated
            .isAtSameMomentAs(
          localUpdated,
        )) {
      await db.update(
        'quiz_progress',
        {
          'best_score': mergedBest,
          'last_score': lastScore,
          'total_questions':
              totalQuestions,
          'completed':
              mergedCompleted ? 1 : 0,
          'unlocked':
              mergedUnlocked ? 1 : 0,
          'updated_at': updatedAt,
          'pending_sync': 0,
        },
        where:
            'user_id = ? '
            'AND prophet_id = ? '
            'AND level = ?',
        whereArgs: [
          userId,
          prophetId,
          level,
        ],
      );
    }
  }

  Future<void> claimGuestProgress(
    String userId,
  ) async {
    final db = await database;

    final guestId =
        await getGuestUserId();

    if (guestId == userId) {
      return;
    }

    await db.transaction((txn) async {
      final guestProgress =
          await txn.query(
        'quiz_progress',
        where: 'user_id = ?',
        whereArgs: [guestId],
      );

      final now =
          DateTime.now()
              .toUtc()
              .toIso8601String();

      final progressBatch =
          txn.batch();

      for (final row in guestProgress) {
        final existing =
            await txn.query(
          'quiz_progress',
          columns: [
            'best_score',
            'completed',
            'unlocked',
          ],
          where:
              'user_id = ? '
              'AND prophet_id = ? '
              'AND level = ?',
          whereArgs: [
            userId,
            row['prophet_id'],
            row['level'],
          ],
          limit: 1,
        );

        if (existing.isEmpty) {
          progressBatch.insert(
            'quiz_progress',
            {
              'user_id': userId,
              'prophet_id':
                  row['prophet_id'],
              'level': row['level'],
              'best_score':
                  row['best_score'],
              'last_score':
                  row['last_score'],
              'total_questions':
                  row['total_questions'],
              'completed':
                  row['completed'],
              'unlocked':
                  row['unlocked'],
              'updated_at': now,
              'pending_sync': 1,
            },
          );
        } else {
          final oldBest =
              (existing.first[
                          'best_score']
                      as int?) ??
                  0;

          final guestBest =
              (row['best_score']
                      as int?) ??
                  0;

          progressBatch.update(
            'quiz_progress',
            {
              'best_score':
                  oldBest > guestBest
                      ? oldBest
                      : guestBest,
              'completed':
                  (existing.first[
                                  'completed'] ==
                              1 ||
                          row['completed'] ==
                              1)
                      ? 1
                      : 0,
              'unlocked':
                  (existing.first[
                                  'unlocked'] ==
                              1 ||
                          row['unlocked'] ==
                              1)
                      ? 1
                      : 0,
              'pending_sync': 1,
              'updated_at': now,
            },
            where:
                'user_id = ? '
                'AND prophet_id = ? '
                'AND level = ?',
            whereArgs: [
              userId,
              row['prophet_id'],
              row['level'],
            ],
          );
        }
      }

      await progressBatch.commit(
        noResult: true,
      );

      await txn.update(
        'quiz_attempts',
        {
          'user_id': userId,
          'pending_sync': 1,
        },
        where: 'user_id = ?',
        whereArgs: [guestId],
      );
    });
  }

  Future<Map<String, int>> getGlobalProgress({
    String? userId,
  }) async {
    final db = await database;

    final effectiveUserId =
        userId ?? await getGuestUserId();

    await ensureQuizProgressForUser(
      effectiveUserId,
    );

    final result = await db.rawQuery(
      '''
      SELECT
        (SELECT COUNT(*)
         FROM prophets) AS prophets,

        COUNT(*) AS levels,

        COALESCE(
          SUM(
            CASE
              WHEN completed = 1
              THEN 1
              ELSE 0
            END
          ),
          0
        ) AS completed_levels,

        (
          SELECT COUNT(*)
          FROM quiz_attempts
          WHERE user_id = ?
        ) AS attempts,

        COALESCE(
          MAX(best_score),
          0
        ) AS best_score,

        COALESCE(
          SUM(total_questions),
          0
        ) AS total_questions

      FROM quiz_progress
      WHERE user_id = ?
      ''',
      [
        effectiveUserId,
        effectiveUserId,
      ],
    );

    final row = result.first;

    return {
      'prophets':
          (row['prophets'] as int?) ?? 0,
      'levels':
          (row['levels'] as int?) ?? 0,
      'completedLevels':
          (row['completed_levels']
                  as int?) ??
              0,
      'attempts':
          (row['attempts'] as int?) ?? 0,
      'bestScore':
          (row['best_score'] as int?) ?? 0,
      'totalQuestions':
          (row['total_questions']
                  as int?) ??
              0,
    };
  }

  Future<Map<String, int>>
      getDatabaseStats() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        (SELECT COUNT(*)
         FROM prophets) AS prophets,

        (SELECT COUNT(*)
         FROM stories) AS stories,

        (SELECT COUNT(*)
         FROM stories
         WHERE audience = 'adult')
         AS adult_stories,

        (SELECT COUNT(*)
         FROM stories
         WHERE audience = 'kids')
         AS kids_stories,

        (SELECT COUNT(*)
         FROM quran_references)
         AS quran_references,

        (SELECT COUNT(*)
         FROM lessons)
         AS lessons,

        (SELECT COUNT(*)
         FROM quiz_questions)
         AS quiz_questions
      ''',
    );

    final row = result.first;

    return {
      'prophets':
          (row['prophets'] as int?) ?? 0,
      'stories':
          (row['stories'] as int?) ?? 0,
      'adultStories':
          (row['adult_stories'] as int?) ?? 0,
      'kidsStories':
          (row['kids_stories'] as int?) ?? 0,
      'quranReferences':
          (row['quran_references']
                  as int?) ??
              0,
      'lessons':
          (row['lessons'] as int?) ?? 0,
      'quizQuestions':
          (row['quiz_questions']
                  as int?) ??
              0,
    };
  }

  Future<void> resetQuizzes() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('quiz_attempts');
      await txn.delete('quiz_progress');
      await txn.delete('quiz_questions');
    });

    await importQuizzes();
  }

  Future<void> resetAndImport() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'online_match_questions',
      );

      await txn.delete(
        'online_match_cache',
      );

      await txn.delete(
        'online_quiz_progress',
      );

      await txn.delete(
        'quiz_attempts',
      );

      await txn.delete(
        'quiz_progress',
      );

      await txn.delete(
        'quiz_questions',
      );

      await txn.delete(
        'lessons',
      );

      await txn.delete(
        'quran_references',
      );

      await txn.delete(
        'stories',
      );

      await txn.delete(
        'prophets',
      );
    });

    _cachedProphets = null;

    await importProphetStories();
    await importQuizzes();
  }

  Future<void> saveSetting(
    String key,
    String value,
  ) async {
    final db = await database;

    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(
    String key,
  ) async {
    final db = await database;

    final result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value']
        ?.toString();
  }

  Future<void> deleteSetting(
    String key,
  ) async {
    final db = await database;

    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> saveThemeMode(
    String mode,
  ) async {
    if (mode != 'light' &&
        mode != 'dark' &&
        mode != 'system') {
      throw ArgumentError(
        'Mode de thème invalide : $mode',
      );
    }

    await saveSetting(
      'theme_mode',
      mode,
    );
  }

  Future<String> getThemeMode() async {
    final value =
        await getSetting(
      'theme_mode',
    );

    switch (value) {
      case 'light':
        return 'light';

      case 'dark':
        return 'dark';

      case 'system':
      default:
        return 'system';
    }
  }

  Future<void> close() async {
    final db = _database;

    if (db == null) {
      return;
    }

    await db.close();

    _database = null;
    _cachedGuestId = null;
    _cachedProphets = null;
  }
}