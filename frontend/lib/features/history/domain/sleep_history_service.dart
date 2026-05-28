import '../data/models/sleep_entry.dart';

abstract class SleepHistoryService {
  Future<List<SleepEntry>> getSleepHistory();

  Future<void> addSleepEntry(SleepEntry entry);

  Future<void> updateSleepEntry(SleepEntry entry);

  Future<Map<String, dynamic>> getSummaryStats();
}
