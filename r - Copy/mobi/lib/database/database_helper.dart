import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import '../models/game_session_model.dart';
import '../models/reminder_model.dart';
import '../models/mood_model.dart';
import '../models/memory_item_model.dart';
import '../models/onboarding_model.dart';
import '../models/assessment_model.dart';
import '../models/meaningful_activity_model.dart';
import '../models/rewards_model.dart';

/// DatabaseHelper with Web-Safe Persistence Layer:
/// - On Android/iOS: Uses native SQLite via sqflite.
/// - On Flutter Web: Uses SharedPreferences & in-memory web repository to prevent MissingPluginException.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;

  // Web in-memory caches
  final List<GameSessionModel> _webSessions = [];
  final List<ReminderModel> _webReminders = [];
  final List<MoodModel> _webMoods = [];
  final List<MemoryItemModel> _webMemoryItems = [];
  final List<OnboardingAnswer> _webOnboardingAnswers = [];
  final List<AssessmentSession> _webAssessmentSessions = [];
  final List<ActivityLog> _webActivityLogs = [];
  final List<Map<String, dynamic>> _webInitialAssessments = [];
  final RewardsState _rewardsState = RewardsState();
  final Set<String> _awardedSessionIds = {};
  bool _webInitialized = false;

  DatabaseHelper._init();

  Future<sqflite.Database?> get database async {
    if (kIsWeb) return null;
    try {
      if (_database != null) return _database!;
      _database = await _initDB('neural_nexus_local.db');
      return _database;
    } catch (e) {
      debugPrint('[DatabaseHelper] SQLite init fallback to in-memory: $e');
      return null;
    }
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await sqflite.openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createDB(db, version);
        await _createInitialAssessmentTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createInitialAssessmentTables(db);
      },
      onOpen: (db) async {
        await _createInitialAssessmentTables(db);
      },
    );
  }

  Future<void> _createInitialAssessmentTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS initial_assessments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        language TEXT NOT NULL,
        notes TEXT,
        yes_count INTEGER NOT NULL,
        no_count INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        synced INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS initial_assessment_responses (
        id TEXT PRIMARY KEY,
        assessment_id TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        character_name TEXT NOT NULL,
        location TEXT NOT NULL,
        question_text TEXT NOT NULL,
        story_summary TEXT,
        answer TEXT NOT NULL,
        language TEXT NOT NULL,
        answered_at TEXT NOT NULL
      )
    ''');
  }


  Future<void> _createDB(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE game_sessions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        category TEXT NOT NULL,
        level INTEGER NOT NULL,
        score INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        attempts INTEGER NOT NULL,
        mistakes INTEGER NOT NULL,
        response_time_ms INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        offline_created INTEGER NOT NULL,
        synced INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        title TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        frequency TEXT NOT NULL,
        completed INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_logs (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        mood TEXT NOT NULL,
        note TEXT,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE memory_items (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        details TEXT NOT NULL,
        relationship TEXT,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _initWebDefaults(String patientId) async {
    if (_webInitialized) return;
    _webInitialized = true;

    // Seed web reminders for demo
    if (_webReminders.isEmpty) {
      _webReminders.addAll([
        ReminderModel(
          id: 'r_web_1',
          patientId: patientId,
          title: 'Afternoon Blood Pressure Medicine',
          reminderType: 'medicine',
          timeOfDay: '02:00 PM',
          notes: 'Take with lukewarm water after lunch.',
          completed: false,
        ),
        ReminderModel(
          id: 'r_web_2',
          patientId: patientId,
          title: 'Afternoon Hydration — Warm Water',
          reminderType: 'hydration',
          timeOfDay: '04:00 PM',
          notes: 'Drink 1 full glass of fresh water.',
          completed: false,
        ),
        ReminderModel(
          id: 'r_web_3',
          patientId: patientId,
          title: 'Morning Walk in the Garden',
          reminderType: 'daily_activity',
          timeOfDay: '08:00 AM',
          completed: true,
        ),
      ]);
    }
  }

  // --- Game Sessions ---
  Future<void> insertSession(GameSessionModel session) async {
    if (kIsWeb) {
      _webSessions.removeWhere((s) => s.id == session.id);
      _webSessions.insert(0, session);
      return;
    }
    final db = await database;
    if (db == null) {
      _webSessions.removeWhere((s) => s.id == session.id);
      _webSessions.insert(0, session);
      return;
    }
    await db.insert('game_sessions', session.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<List<GameSessionModel>> getSessions(String patientId) async {
    if (kIsWeb) {
      await _initWebDefaults(patientId);
      return _webSessions.where((s) => s.patientId == patientId).toList();
    }
    final db = await database;
    if (db == null) {
      await _initWebDefaults(patientId);
      return _webSessions.where((s) => s.patientId == patientId).toList();
    }
    final maps = await db.query(
      'game_sessions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => GameSessionModel.fromMap(m)).toList();
  }

  // --- Reminders ---
  Future<void> insertReminder(ReminderModel reminder) async {
    if (kIsWeb) {
      _webReminders.removeWhere((r) => r.id == reminder.id);
      _webReminders.add(reminder);
      return;
    }
    final db = await database;
    if (db == null) {
      _webReminders.removeWhere((r) => r.id == reminder.id);
      _webReminders.add(reminder);
      return;
    }
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<void> updateReminderStatus(String id, bool completed) async {
    if (kIsWeb) {
      final idx = _webReminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _webReminders[idx] = _webReminders[idx].copyWith(completed: completed);
      }
      return;
    }
    final db = await database;
    if (db == null) {
      final idx = _webReminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _webReminders[idx] = _webReminders[idx].copyWith(completed: completed);
      }
      return;
    }
    await db.update(
      'reminders',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ReminderModel>> getReminders(String patientId) async {
    if (kIsWeb) {
      await _initWebDefaults(patientId);
      return _webReminders.where((r) => r.patientId == patientId).toList();
    }
    final db = await database;
    if (db == null) {
      await _initWebDefaults(patientId);
      return _webReminders.where((r) => r.patientId == patientId).toList();
    }
    final maps = await db.query(
      'reminders',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    return maps.map((m) => ReminderModel.fromMap(m)).toList();
  }

  // --- Mood Logs ---
  Future<void> insertMood(MoodModel mood) async {
    if (kIsWeb) {
      _webMoods.insert(0, mood);
      return;
    }
    final db = await database;
    if (db == null) {
      _webMoods.insert(0, mood);
      return;
    }
    await db.insert('mood_logs', mood.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<List<MoodModel>> getMoods(String patientId) async {
    if (kIsWeb) {
      return _webMoods.where((m) => m.patientId == patientId).toList();
    }
    final db = await database;
    if (db == null) {
      return _webMoods.where((m) => m.patientId == patientId).toList();
    }
    final maps = await db.query(
      'mood_logs',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'logged_at DESC',
    );
    return maps.map((m) => MoodModel.fromMap(m)).toList();
  }

  // --- Memory Items ---
  Future<void> insertMemoryItem(MemoryItemModel item) async {
    if (kIsWeb) {
      _webMemoryItems.add(item);
      return;
    }
    final db = await database;
    if (db == null) {
      _webMemoryItems.add(item);
      return;
    }
    await db.insert('memory_items', item.toMap(), conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<List<MemoryItemModel>> getMemoryItems(String patientId) async {
    if (kIsWeb) {
      return _webMemoryItems.where((item) => item.patientId == patientId).toList();
    }
    final db = await database;
    if (db == null) {
      return _webMemoryItems.where((item) => item.patientId == patientId).toList();
    }
    final maps = await db.query(
      'memory_items',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    return maps.map((m) => MemoryItemModel.fromMap(m)).toList();
  }

  // --- Onboarding Answers ---
  Future<void> saveOnboardingAnswer(OnboardingAnswer ans) async {
    _webOnboardingAnswers.removeWhere((a) => a.questionId == ans.questionId);
    _webOnboardingAnswers.add(ans);
  }

  Future<List<OnboardingAnswer>> getOnboardingAnswers() async {
    return List.unmodifiable(_webOnboardingAnswers);
  }

  // --- 10-Story Assessment Sessions ---
  Future<void> insertAssessmentSession(AssessmentSession session) async {
    _webAssessmentSessions.add(session);
    _rewardsState.addXp(30);
  }

  Future<List<AssessmentSession>> getAssessmentSessions(String patientId) async {
    return _webAssessmentSessions.where((s) => s.patientId == patientId).toList();
  }

  // --- Initial 10-Question Assessment (Problem 7 & New User Flow) ---
  Future<void> insertInitialAssessment({
    required String patientId,
    required String language,
    String? notes,
    required List<InitialAssessmentResponseItem> responses,
  }) async {
    final id = 'assess_${patientId}_${DateTime.now().millisecondsSinceEpoch}';
    final yesCount = responses.where((r) => r.answer.toLowerCase() == 'yes').length;
    final noCount = responses.where((r) => r.answer.toLowerCase() == 'no').length;
    final nowIso = DateTime.now().toIso8601String();

    final assessMap = {
      'id': id,
      'patient_id': patientId,
      'language': language,
      'notes': notes ?? '10-Question Initial Screening Assessment',
      'yes_count': yesCount,
      'no_count': noCount,
      'completed': 1,
      'completed_at': nowIso,
      'synced': 0,
      'responses': responses.map((r) => r.toJson()).toList(),
    };

    _webInitialAssessments.removeWhere((a) => a['patient_id'] == patientId);
    _webInitialAssessments.add(assessMap);

    // Save 50 XP for completing assessment
    await addRewardXp(patientId, 50, eventKey: 'assessment_$id');

    if (!kIsWeb) {
      final db = await database;
      if (db != null) {
        try {
          await db.insert('initial_assessments', {
            'id': id,
            'patient_id': patientId,
            'language': language,
            'notes': notes ?? '10-Question Initial Screening Assessment',
            'yes_count': yesCount,
            'no_count': noCount,
            'completed': 1,
            'completed_at': nowIso,
            'synced': 0,
          }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);

          for (final r in responses) {
            await db.insert(
              'initial_assessment_responses',
              r.toMap(id),
              conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
            );
          }
        } catch (e) {
          debugPrint('[DatabaseHelper] Error saving initial assessment to SQLite: $e');
        }
      }
    }

    // Try posting to backend if available
    try {
      final backendUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
      await http.post(
        Uri.parse('$backendUrl/patients/$patientId/initial-assessment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'language': language,
          'notes': notes ?? '10-Question Initial Screening Assessment',
          'responses': responses.map((r) => r.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      debugPrint('[DatabaseHelper] Assessment saved locally; will sync with backend when online.');
    }
  }

  Future<Map<String, dynamic>?> getInitialAssessment(String patientId) async {
    // Check web / memory cache first
    final mem = _webInitialAssessments.where((a) => a['patient_id'] == patientId).toList();
    if (mem.isNotEmpty) return mem.last;

    if (!kIsWeb) {
      final db = await database;
      if (db != null) {
        try {
          final rows = await db.query(
            'initial_assessments',
            where: 'patient_id = ?',
            whereArgs: [patientId],
            orderBy: 'completed_at DESC',
            limit: 1,
          );
          if (rows.isNotEmpty) {
            final assess = Map<String, dynamic>.from(rows.first);
            final respRows = await db.query(
              'initial_assessment_responses',
              where: 'assessment_id = ?',
              whereArgs: [assess['id']],
              orderBy: 'question_id ASC',
            );
            assess['responses'] = respRows.map((m) => InitialAssessmentResponseItem.fromMap(m).toJson()).toList();
            return assess;
          }
        } catch (e) {
          debugPrint('[DatabaseHelper] Error querying initial assessment: $e');
        }
      }
    }
    return null;
  }

  // --- Dynamic Data-Driven Progress Calculations ---
  Future<int> getCompletedGamesCount(String patientId) async {
    final sessions = await getSessions(patientId);
    final now = DateTime.now();
    final todaySessions = sessions.where((s) {
      return s.completed &&
          s.completedAt.year == now.year &&
          s.completedAt.month == now.month &&
          s.completedAt.day == now.day;
    }).toList();
    return todaySessions.length;
  }

  Future<double> getDailyProgressPercentage(String patientId, {int targetGames = 4}) async {
    final completedGames = await getCompletedGamesCount(patientId);
    final reminders = await getReminders(patientId);
    final completedReminders = reminders.where((r) => r.completed).length;
    final totalReminders = reminders.isEmpty ? 1 : reminders.length;

    final gamePart = (completedGames.clamp(0, targetGames) / targetGames) * 75.0;
    final reminderPart = (completedReminders / totalReminders) * 25.0;
    final total = (gamePart + reminderPart).clamp(0.0, 100.0);
    return double.parse(total.toStringAsFixed(1));
  }

  // --- Meaningful Activities ---
  Future<void> logMeaningfulActivity(ActivityLog log) async {
    _webActivityLogs.add(log);
    await addRewardXp(log.patientId, log.xpEarned, eventKey: 'act_${log.id}');
  }

  Future<List<ActivityLog>> getActivityLogs(String patientId) async {
    return _webActivityLogs.where((l) => l.patientId == patientId).toList();
  }

  // --- Rewards State Persistence ---
  RewardsState get rewardsState => _rewardsState;

  Future<RewardsState> loadRewards(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt('rewards_xp_$patientId');
      if (xp != null) {
        _rewardsState.xp = xp;
        _rewardsState.gamificationLevel = prefs.getInt('rewards_lvl_$patientId') ?? ((xp / 100).floor() + 1);
        _rewardsState.streakDays = prefs.getInt('rewards_streak_$patientId') ?? 1;
        _rewardsState.dailyRewardUnlockedToday = prefs.getBool('rewards_unlocked_today_$patientId') ?? false;
      }
    } catch (_) {}
    return _rewardsState;
  }

  Future<void> addRewardXp(String patientId, int amount, {String? eventKey}) async {
    if (eventKey != null) {
      if (_awardedSessionIds.contains(eventKey)) return; // Avoid duplicate rewards
      _awardedSessionIds.add(eventKey);
    }
    _rewardsState.addXp(amount);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rewards_xp_$patientId', _rewardsState.xp);
      await prefs.setInt('rewards_lvl_$patientId', _rewardsState.gamificationLevel);
      await prefs.setInt('rewards_streak_$patientId', _rewardsState.streakDays);
    } catch (_) {}
  }
}

