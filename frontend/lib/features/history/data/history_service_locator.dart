import 'datasources/firestore_sleep_history_store.dart';
import 'repositories/sleep_history_repository.dart';

final SleepHistoryRepository sleepHistoryService =
    SleepHistoryRepository(store: FirestoreSleepHistoryStore());
