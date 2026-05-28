import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/core/api_client.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:flutter/foundation.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _frequencyToPriority(String frequency) {
    switch (frequency) {
      case 'Daily':
        return 'high';
      case '3×/wk':
        return 'medium';
      case '2×/wk':
      case '1×/wk':
        return 'low';
      default:
        return 'medium';
    }
  }

  String _priorityToFrequency(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Daily';
      case 'medium':
        return '3×/wk';
      case 'low':
        return '2×/wk';
      default:
        return 'Daily';
    }
  }

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

      try {
        final response = await ApiClient.postScheduleItemCreate({
          'userId': userId,
          'title': commitment.name,
          'startTime': startIso,
          'endTime': endIso,
          'date': targetDate,
        });

        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'scheduleItemCreate failed');
        }
      } catch (_) {
        await collectionRef.add({
          'userId': userId,
          'title': commitment.name,
          'startTime': startIso,
          'endTime': endIso,
          'date': targetDate,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getManualScheduleItems({
    required String userId,
    required List<String> dates,
  }) async {
    final items = <Map<String, dynamic>>[];
    bool apiWorked = false;

    for (final date in dates) {
      try {
        final response = await ApiClient.getScheduleItemList(
          userId: userId,
          date: date,
        );
        if (response['success'] == true) {
          apiWorked = true;
          final data = response['data'] as Map<String, dynamic>?;
          final rawItems = data?['items'] as List?;
          if (rawItems != null) {
            for (final raw in rawItems.whereType<Map>()) {
              items.add(raw.map((key, value) => MapEntry(key.toString(), value)));
            }
          }
        }
      } catch (_) {
        // Continue and use Firestore fallback if needed.
      }
    }

    if (apiWorked) {
      return items;
    }

    final snapshot = await _firestore
        .collection('scheduleItems')
        .where('userId', isEqualTo: userId)
        .where('date', whereIn: dates)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      items.add({
        'itemId': doc.id,
        ...data,
      });
    }
    return items;
  }

  Future<List<Goal>> loadGoals({required String userId}) async {
    try {
      final response = await ApiClient.getGoalItemList(userId: userId);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final rawGoals = data?['goals'] as List?;
        if (rawGoals != null) {
          return rawGoals.whereType<Map>().map((rawGoal) {
            final goal = rawGoal.map((key, value) => MapEntry(key.toString(), value));
            final title = goal['title']?.toString() ?? '';
            final estimatedMinutes = (goal['estimatedMinutes'] as num?)?.round() ?? 30;
            final priority = goal['priority']?.toString() ?? 'medium';
            return Goal(
              name: title,
              duration: estimatedMinutes,
              frequency: _priorityToFrequency(priority),
            );
          }).toList();
        }
      }
    } catch (_) {
      // fall back to preferences/local
    }
    return const [];
  }

  Future<void> syncGoalsToApi({
    required String userId,
    required List<Goal> goals,
  }) async {
    try {
      final response = await ApiClient.getGoalItemList(userId: userId);
      final existingSignatures = <String>{};
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final rawGoals = data?['goals'] as List?;
        if (rawGoals != null) {
          for (final raw in rawGoals.whereType<Map>()) {
            final map = raw.map((key, value) => MapEntry(key.toString(), value));
            final title = map['title']?.toString() ?? '';
            final mins = (map['estimatedMinutes'] as num?)?.round() ?? 0;
            final priority = map['priority']?.toString().toLowerCase() ?? '';
            existingSignatures.add('$title|$mins|$priority');
          }
        }
      }

      for (final goal in goals) {
        final priority = _frequencyToPriority(goal.frequency);
        final signature = '${goal.name}|${goal.duration}|$priority';
        if (existingSignatures.contains(signature)) {
          continue;
        }
        await ApiClient.postGoalItemCreate({
          'userId': userId,
          'title': goal.name,
          'estimatedMinutes': goal.duration,
          'priority': priority,
        });
      }
    } catch (_) {
      // non-blocking sync
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
      return ApiClient.postGenerateSchedulePlan({
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
