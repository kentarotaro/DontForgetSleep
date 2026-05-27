import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:flutter/foundation.dart';

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
    if (_store is FirestoreSleepHistoryStore) {
      await (_store as FirestoreSleepHistoryStore).loadEntries();
      _entries = _store.seedEntries();
      notifyListeners();
    }
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
