import 'package:uuid/uuid.dart';

import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

import '../../domain/sleep_history_store.dart';
import '../models/sleep_entry.dart';

class MockSleepHistoryStore implements SleepHistoryStore {
  final List<SleepEntry> _entries = [];
  final _uuid = const Uuid();

  MockSleepHistoryStore() {
    _generateDummyData();
  }

  void _generateDummyData() {
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final startHour = 22 + (date.day % 3);
      final durationHours = 6 + (date.day % 3) + (i % 2 == 0 ? 1 : 0);
      final durationMinutes = (date.day * 5) % 60;

      final startTime = DateTime(date.year, date.month, date.day - 1, startHour, durationMinutes);
      final endTime = startTime.add(Duration(hours: durationHours, minutes: 30));

      _entries.add(
        SleepEntry(
          id: _uuid.v4(),
          startTime: startTime,
          endTime: endTime,
          type: SleepType.nightSleep,
          quality: (date.day % 3) + 3,
        ),
      );

      if (i % 3 == 0) {
        final napStart = DateTime(date.year, date.month, date.day, 14, 0);
        final napEnd = napStart.add(const Duration(minutes: 45));

        _entries.add(
          SleepEntry(
            id: _uuid.v4(),
            startTime: napStart,
            endTime: napEnd,
            type: SleepType.nap,
            quality: 4,
          ),
        );
      }
    }

    _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  @override
  List<SleepEntry> seedEntries() {
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> addSleepEntry(SleepEntry entry) async {
    final newEntry = SleepEntry(
      id: _uuid.v4(),
      startTime: entry.startTime,
      endTime: entry.endTime,
      type: entry.type,
      quality: entry.quality,
      notes: entry.notes,
    );
    _entries.add(newEntry);
    _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  @override
  Future<void> updateSleepEntry(SleepEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) return;

    _entries[index] = entry;
    _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Map<String, dynamic> getSummaryStats(List<SleepEntry> entries) {
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
