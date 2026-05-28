import '../data/models/sleep_entry.dart';

abstract class SleepHistoryStore {
  List<SleepEntry> seedEntries();

  Future<void> addSleepEntry(SleepEntry entry);

  Future<void> updateSleepEntry(SleepEntry entry);
}
