import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/core/api_client.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:flutter/foundation.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate list of YYYY-MM-DD dates for the current week (Monday to Sunday)
  List<String> getCurrentWeekDates() {
    final now = DateTime.now();
    // Monday is 1, Sunday is 7 in Dart's weekday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });
  }

  /// Converts double decimal hour (e.g. 8.5 for 08:30) to ISO 8601 UTC string
  String _doubleHourToIsoUtc(String dateStr, double doubleHour) {
    final parts = dateStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    final hour = doubleHour.floor();
    final minute = ((doubleHour - hour) * 60).round();

    // Parse as local DateTime then convert to UTC
    final localDateTime = DateTime(year, month, day, hour, minute);
    return localDateTime.toUtc().toIso8601String();
  }

  /// Saves commitments to Firestore after deleting existing ones for the dates
  Future<void> saveCommitmentsToFirestore({
    required String userId,
    required List<Commitment> commitments,
    required List<String> dates,
  }) async {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // 1. Delete existing manual scheduleItems for this user on these dates
    final collectionRef = _firestore.collection('scheduleItems');
    for (final date in dates) {
      final querySnapshot = await collectionRef
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: date)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }

    // 2. Insert new scheduleItems
    for (final commitment in commitments) {
      final dayIndex = days.indexOf(commitment.day);
      if (dayIndex == -1 || dayIndex >= dates.length) continue;

      final targetDate = dates[dayIndex];
      final startIso = _doubleHourToIsoUtc(targetDate, commitment.start);
      final endIso = _doubleHourToIsoUtc(targetDate, commitment.end);

      await collectionRef.add({
        'userId': userId,
        'title': commitment.name,
        'startTime': startIso,
        'endTime': endIso,
        'date': targetDate,
      });
    }
  }

  /// Invokes generateSchedulePlan Cloud Function for each date in parallel
  Future<Map<String, dynamic>> generateAIWeeklySchedule({
    required String userId,
    required List<String> dates,
  }) async {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, List<ScheduleBlock>> weeklySchedule = {};
    final List<String> advices = [];

    // Trigger Cloud Function in parallel
    final futures = dates.map((date) {
      return ApiClient.post(ApiEndpoints.generateSchedulePlan, {
        'userId': userId,
        'date': date,
      }).timeout(const Duration(seconds: 25)).catchError((err) {
        // Return fallback/error map if call fails
        if (kDebugMode) {
          // ignore: avoid_print
          print('AI schedule request failed for $date: $err');
        }
        return {
          'success': false,
          'message': err.toString(),
        };
      });
    }).toList();

    final responses = await Future.wait(futures);

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final dayName = days[i];
      final targetDate = dates[i];

      final success = response['success'] ?? true;
      if (success) {
        final data = response['data'] ?? response;
        final List? plannedItems = data['plannedItems'] as List?;
        final String? advice = data['advice'] as String?;

        if (advice != null && advice.isNotEmpty) {
          advices.add('$dayName: $advice');
        }

        final List<ScheduleBlock> blocks = [];
        if (plannedItems != null) {
          for (final item in plannedItems) {
            final title = item['title'] ?? '';
            final startStr = item['startTime'] ?? '';
            final endStr = item['endTime'] ?? '';

            if (startStr.isNotEmpty && endStr.isNotEmpty) {
              final startDouble = _isoToDoubleHour(startStr, targetDate);
              final endDouble = _isoToDoubleHour(endStr, targetDate);

              // Map types based on name/goals. For simplification we default to 'goal'.
              // Sleep will be added dynamically by local parser or backend.
              blocks.add(ScheduleBlock(
                name: title,
                start: startDouble,
                end: endDouble,
                type: title.toLowerCase().contains('sleep') ? 'sleep' : 'goal',
              ));
            }
          }
        }
        weeklySchedule[dayName] = blocks;
      } else {
        // If one day fails, throw exception to let parent catch and fallback
        throw Exception(response['message'] ?? 'API failed for $targetDate');
      }
    }

    return {
      'schedule': weeklySchedule,
      'advice': advices.join('\n\n'),
    };
  }

  /// Converts UTC ISO 8601 back to local double decimal hour
  double _isoToDoubleHour(String isoStr, String targetDateStr) {
    try {
      final parsedUtc = DateTime.parse(isoStr).toUtc();
      
      // Convert parsed UTC to local time
      final localDateTime = parsedUtc.toLocal();
      
      // Return local hours + minutes as double
      return localDateTime.hour + (localDateTime.minute / 60.0);
    } catch (_) {
      return 12.0; // Fallback
    }
  }

  /// Fetches Google Calendar events for the week from Firestore
  Future<Map<String, List<ScheduleBlock>>> getGoogleCalendarEvents({
    required String userId,
    required List<String> dates,
  }) async {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, List<ScheduleBlock>> calendarMap = {};
    for (final day in days) {
      calendarMap[day] = [];
    }

    try {
      final startLocal = DateTime.parse('${dates.first}T00:00:00');
      final endLocal = DateTime.parse('${dates.last}T23:59:59');

      final startTimestamp = Timestamp.fromDate(startLocal.toUtc());
      final endTimestamp = Timestamp.fromDate(endLocal.toUtc());

      final snapshot = await _firestore
          .collection('calendarEvents')
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('startTime', isLessThanOrEqualTo: endTimestamp)
          .get();

      for (final doc in querySnapshotDocs(snapshot)) {
        final data = doc.data();
        final title = data['title'] ?? 'Google Event';
        final Timestamp? startTime = data['startTime'] as Timestamp?;
        final Timestamp? endTime = data['endTime'] as Timestamp?;

        if (startTime != null && endTime != null) {
          final sLocal = startTime.toDate().toLocal();
          final eLocal = endTime.toDate().toLocal();

          final weekdayIndex = sLocal.weekday - 1;
          if (weekdayIndex >= 0 && weekdayIndex < 7) {
            final dayName = days[weekdayIndex];
            final startDouble = sLocal.hour + (sLocal.minute / 60.0);
            final endDouble = eLocal.hour + (eLocal.minute / 60.0);

            calendarMap[dayName]!.add(ScheduleBlock(
              name: '📅 $title',
              start: startDouble,
              end: endDouble,
              type: 'calendar',
            ));
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching Google Calendar events from Firestore: $e');
    }

    return calendarMap;
  }

  // Helper helper to bypass issues with dynamic collections
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> querySnapshotDocs(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs;
  }
}
