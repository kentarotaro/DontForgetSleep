import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dont_forget_sleep/core/api_client.dart';

import '../../domain/sleep_history_service.dart';
import '../../domain/sleep_history_store.dart';
import '../models/sleep_entry.dart';
import '../datasources/firestore_sleep_history_store.dart';

class SleepHistoryRepository extends ChangeNotifier implements SleepHistoryService {
  final SleepHistoryStore _store;
  List<SleepEntry> _entries;

  SleepHistoryRepository({required SleepHistoryStore store})
      : _store = store,
        _entries = store.seedEntries();

  Future<void> fetchSleepHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final apiEntries = await _fetchSleepHistoryFromApi(uid);
      if (apiEntries != null) {
        _entries = apiEntries;
        notifyListeners();
        return;
      }
    }

    final store = _store;
    if (store is FirestoreSleepHistoryStore) {
      await store.loadEntries();
      _entries = _store.seedEntries();
      notifyListeners();
    }
  }

  Future<List<SleepEntry>?> _fetchSleepHistoryFromApi(String uid) async {
    try {
      final response = await ApiClient.getSleepHistory(userId: uid, days: 30);
      if (response['success'] != true) {
        return null;
      }

      final data = response['data'] as Map<String, dynamic>?;
      final logs = data?['logs'] as List?;
      if (logs == null) {
        return null;
      }

      final mapped = <SleepEntry>[];
      for (int i = 0; i < logs.length; i++) {
        final raw = logs[i];
        if (raw is! Map) {
          continue;
        }
        final log = raw.map((key, value) => MapEntry(key.toString(), value));
        final date = log['date']?.toString() ?? '';
        final bedtime = log['bedtime']?.toString() ?? '';
        final wakeTime = log['wakeTime']?.toString() ?? '';
        final quality = (log['quality'] as num?)?.round() ?? 3;

        final startTime = _parseApiDateTime(
          date: date,
          value: bedtime,
          fallbackHour: 23,
        );
        final endTime = _parseApiDateTime(
          date: date,
          value: wakeTime,
          fallbackHour: 7,
        );

        mapped.add(SleepEntry(
          id: log['logId']?.toString() ?? 'sleep_${uid}_$date',
          startTime: startTime,
          endTime: endTime.isBefore(startTime)
              ? endTime.add(const Duration(days: 1))
              : endTime,
          quality: quality,
          type: SleepType.nightSleep,
        ));
      }

      mapped.sort((a, b) => b.startTime.compareTo(a.startTime));
      return mapped;
    } catch (_) {
      return null;
    }
  }

  DateTime _parseApiDateTime({
    required String date,
    required String value,
    required int fallbackHour,
  }) {
    try {
      if (value.contains('T')) {
        return DateTime.parse(value).toLocal();
      }
      if (value.contains(':') && date.isNotEmpty) {
        final parts = value.split(':');
        if (parts.length >= 2) {
          final ymd = date.split('-');
          if (ymd.length == 3) {
            return DateTime(
              int.parse(ymd[0]),
              int.parse(ymd[1]),
              int.parse(ymd[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        }
      }
    } catch (_) {
      // Fallback below
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, fallbackHour);
  }

  @override
  Future<List<SleepEntry>> getSleepHistory() async {
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> addSleepEntry(SleepEntry entry) async {
    await _store.addSleepEntry(entry);
    _entries = _store.seedEntries();
    notifyListeners();
  }

  @override
  Future<void> updateSleepEntry(SleepEntry entry) async {
    await _store.updateSleepEntry(entry);
    _entries = _store.seedEntries();
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> getSummaryStats() async {
    return _calculateSummaryStats(_entries);
  }

  List<SleepEntry> get entries => List.unmodifiable(_entries);

  Map<String, dynamic> get summaryStats => _calculateSummaryStats(_entries);

  Map<String, dynamic> _calculateSummaryStats(List<SleepEntry> entries) {
    final nightSleeps = _recentNightSleeps(entries);
    final totalSleep = nightSleeps.fold<Duration>(Duration.zero, (sum, entry) => sum + entry.duration);
    final avgMinutes = nightSleeps.isNotEmpty ? (totalSleep.inMinutes / nightSleeps.length).round() : 0;
    final avgHours = avgMinutes ~/ 60;
    final avgMinsRem = avgMinutes % 60;
    final targetMinutes = sleepPreferencesService.targetSleepFloorHours * 60;
    final metTarget = nightSleeps.where((entry) => entry.duration.inMinutes >= targetMinutes).length;
    final consistency = nightSleeps.isNotEmpty ? ((metTarget / nightSleeps.length) * 100).round() : 0;

    return {
      'averageSleep': '${avgHours}h ${avgMinsRem > 0 ? '${avgMinsRem}m' : ''}',
      'consistency': '$consistency%',
      'dayStreak': _calculateStreak(nightSleeps),
    };
  }

  List<SleepEntry> _recentNightSleeps(List<SleepEntry> entries) {
    final nightSleeps = entries.where((e) => e.type == SleepType.nightSleep).toList();
    return nightSleeps.take(7).toList();
  }

  int _calculateStreak(List<SleepEntry> nightSleeps) {
    if (nightSleeps.isEmpty) return 0;

    final sorted = [...nightSleeps]..sort((a, b) => b.endTime.compareTo(a.endTime));
    final targetMinutes = sleepPreferencesService.targetSleepFloorHours * 60;
    int streak = 0;
    DateTime? expectedDay;

    for (final entry in sorted) {
      final entryDay = DateTime(entry.endTime.year, entry.endTime.month, entry.endTime.day);
      if (entry.duration.inMinutes < targetMinutes) {
        break;
      }

      if (streak == 0) {
        streak = 1;
        expectedDay = entryDay.subtract(const Duration(days: 1));
        continue;
      }

      if (expectedDay != null && entryDay == expectedDay) {
        streak++;
        expectedDay = expectedDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
