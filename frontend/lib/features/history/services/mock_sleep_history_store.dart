// import 'package:uuid/uuid.dart';

// import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

// import '../models/sleep_entry.dart';
// import 'sleep_history_store.dart';

// class MockSleepHistoryStore implements SleepHistoryStore {
//   final List<SleepEntry> _entries = [];
//   final _uuid = const Uuid();

//   MockSleepHistoryStore() {
//     _generateDummyData();
//   }

//   void _generateDummyData() {
//     final now = DateTime.now();

//     for (int i = 0; i < 7; i++) {
//       final date = now.subtract(Duration(days: i));

//       final startHour = 22 + (date.day % 3);
//       final durationHours = 6 + (date.day % 3) + (i % 2 == 0 ? 1 : 0);
//       final durationMinutes = (date.day * 5) % 60;

//       final startTime = DateTime(date.year, date.month, date.day - 1, startHour, durationMinutes);
//       final endTime = startTime.add(Duration(hours: durationHours, minutes: 30));

//       _entries.add(
//         SleepEntry(
//           id: _uuid.v4(),
//           startTime: startTime,
//           endTime: endTime,
//           type: SleepType.nightSleep,
//           quality: (date.day % 3) + 3,
//         ),
//       );

//       if (i % 3 == 0) {
//         final napStart = DateTime(date.year, date.month, date.day, 14, 0);
//         final napEnd = napStart.add(const Duration(minutes: 45));

//         _entries.add(
//           SleepEntry(
//             id: _uuid.v4(),
//             startTime: napStart,
//             endTime: napEnd,
//             type: SleepType.nap,
//             quality: 4,
//           ),
//         );
//       }
//     }

//     export '../data/datasources/mock_sleep_history_store.dart';
export '../data/datasources/mock_sleep_history_store.dart';