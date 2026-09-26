import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

enum SyncStatus { onlineSynced, syncing, offlineSaved }

class SyncEngine extends ChangeNotifier {
  static final SyncEngine instance = SyncEngine._internal();
  SyncEngine._internal();

  SyncStatus _status = SyncStatus.onlineSynced;
  SyncStatus get status => _status;

  String get statusLabel {
    switch (_status) {
      case SyncStatus.onlineSynced:
        return 'Online • Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offlineSaved:
        return 'Offline • Saved';
    }
  }

  void setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  Future<void> triggerSync(String patientId, {String? baseUrl}) async {
    final targetUrl = baseUrl ?? (kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000');
    setStatus(SyncStatus.syncing);
    try {
      final sessions = await DatabaseHelper.instance.getSessions(patientId);
      final unsynced = sessions.where((s) => !s.synced).toList();

      if (unsynced.isNotEmpty) {
        final sessionsPayload = unsynced.map((s) => {
          'patient_id': s.patientId,
          'game_id': s.gameId,
          'category': s.category,
          'level': s.level,
          'score': s.score,
          'accuracy': s.accuracy,
          'attempts': s.attempts,
          'mistakes': s.mistakes,
          'response_time_ms': s.responseTimeMs,
          'duration_seconds': s.durationSeconds,
          'completed': s.completed,
          'offline_created': true
        }).toList();

        final res = await http.post(
          Uri.parse('$targetUrl/sync'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patient_id': patientId,
            'sessions': sessionsPayload,
            'reminders_completed': [],
            'moods': []
          }),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          setStatus(SyncStatus.onlineSynced);
          return;
        }
      }
      setStatus(SyncStatus.onlineSynced);
    } catch (_) {
      setStatus(SyncStatus.offlineSaved);
    }
  }
}
