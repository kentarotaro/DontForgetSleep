import '../../../services/sleep_preferences_service.dart';
import '../models/rescue_plan_model.dart';

abstract class RescueAdvisorService {
  Future<RescuePlan> generatePlan({
    required String userId,
    required double sleepHours,
    required int energyLevel,
    required int sleepDebtMinutes,
  });
}

RescuePlan parseRescuePlan({
  required Map<String, dynamic> data,
  required double sleepHours,
}) {
  final suggestion = data['sleepWindowSuggestion'] as Map<String, dynamic>?;
  final recommendedBedtime = suggestion?['recommendedBedtime']?.toString() ?? '22:00';

  final caffeineAdvice = data['caffeineAdvice']?.toString() ?? '';
  final caffeineStop = _extractTimeFromText(caffeineAdvice) ?? '14:00';

  final checklistItems = _extractChecklistItems(data);
  final List<ChecklistItem> checklist = [];
  String? napWindow;

  int index = 0;
  for (final item in checklistItems) {
    final action = _stringValue(
      item['action'] ?? item['text'] ?? item['title'] ?? item['description'],
    );
    if (action.isEmpty) {
      continue;
    }

    napWindow ??= _extractTimeFromText(action);
    napWindow ??= _extractTimeFromText(item['window']?.toString());
    napWindow ??= _extractTimeFromText(item['time']?.toString());

    final durationMinutes = item['durationMinutes'];
    final priority = _stringValue(item['priority']);
    final annotations = <String>[];
    if (durationMinutes is num && durationMinutes > 0) {
      annotations.add('${durationMinutes.round()}m');
    }
    if (priority.isNotEmpty) {
      annotations.add(priority);
    }

    final id = _stringValue(item['id'], fallback: 'ai_item_${index++}');
    checklist.add(ChecklistItem(
      id: id,
      text: annotations.isEmpty ? action : '$action (${annotations.join(', ')})',
      isCompleted: false,
    ));
  }

  napWindow ??= _extractTimeFromText(suggestion?['recommendedWakeTime']?.toString());

  final targetFloor = sleepPreferencesService.targetSleepFloorHours;
  final type = sleepHours < targetFloor 
      ? RescueType.underslept 
      : (sleepHours > 9 ? RescueType.overslept : RescueType.normal);

  final subtitle = caffeineAdvice.isNotEmpty
      ? caffeineAdvice
      : type == RescueType.underslept
          ? "Below target! Here's your AI-generated recovery plan:"
          : type == RescueType.overslept
              ? "Way above target. Let’s reset your rhythm tonight:"
              : 'Your sleep rhythm looks balanced.';

  return RescuePlan(
    type: type,
    hoursSlept: sleepHours,
    title: '${sleepHours.toStringAsFixed(1)}h slept',
    subtitle: subtitle,
    checklist: checklist,
    napWindow: napWindow,
    caffeineStop: caffeineStop,
    newBedtime: recommendedBedtime,
  );
}

class MockRescueAdvisorService implements RescueAdvisorService {
  String _adjustTime(String timeStr, int hoursOffset) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final adjustedHour = (hour + hoursOffset) % 24;
      final cleanHour = adjustedHour < 0 ? adjustedHour + 24 : adjustedHour;
      return '${cleanHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  List<ChecklistItem> _buildDynamicChecklist({
    required RescueType type,
    required int energyLevel,
    required int sleepDebtMinutes,
    required String wakeTime,
    required String bedtime,
    required String napStart,
    required String napEnd,
    required String caffeineStop,
    required String newBedtime,
    required String sunlightTime,
    required String screenTime,
  }) {
    if (type == RescueType.underslept) {
      final desiredCount = (sleepDebtMinutes >= 120 ? 5 : sleepDebtMinutes >= 60 ? 4 : 3)
          + (energyLevel <= 2 ? 1 : 0);
      final pool = <ChecklistItem>[
        ChecklistItem(
          id: 'nap',
          text: 'Take a 20-min power nap between $napStart-$napEnd',
        ),
        ChecklistItem(
          id: 'caffeine',
          text: 'No caffeine after $caffeineStop today',
        ),
        ChecklistItem(
          id: 'bedtime',
          text: 'Move bedtime to $newBedtime tonight',
        ),
        ChecklistItem(
          id: 'walk',
          text: 'Light walk after dinner for better sleep quality',
        ),
        ChecklistItem(
          id: 'wind_down',
          text: 'Start a screen-free wind-down 30 minutes before bed',
        ),
        ChecklistItem(
          id: 'hydration',
          text: 'Hydrate earlier in the day and slow down fluids near bedtime',
        ),
      ];

      return pool.take(desiredCount.clamp(3, pool.length).toInt()).toList();
    }

    if (type == RescueType.overslept) {
      return [
        ChecklistItem(
          id: 'no_nap',
          text: 'Avoid napping today to reset your clock',
        ),
        ChecklistItem(
          id: 'sunlight',
          text: 'Get sunlight exposure before $sunlightTime',
        ),
        ChecklistItem(
          id: 'bedtime',
          text: 'Target your normal bedtime ($bedtime)',
        ),
        ChecklistItem(
          id: 'screen_time',
          text: 'Limit screen time after $screenTime',
        ),
      ];
    }

    return [];
  }

  @override
  Future<RescuePlan> generatePlan({
    required String userId,
    required double sleepHours,
    required int energyLevel,
    required int sleepDebtMinutes,
  }) async {
    // Simulate network latency for AI response
    await Future.delayed(const Duration(milliseconds: 1500));

    final targetFloor = sleepPreferencesService.targetSleepFloorHours;
    final wakeTime = sleepPreferencesService.preferredWakeTime;
    final bedtime = sleepPreferencesService.preferredBedtime;

    final napStart = _adjustTime(wakeTime, 6);
    final napEnd = _adjustTime(wakeTime, 7);
    final caffeineStop = _adjustTime(bedtime, -9);
    final newBedtime = _adjustTime(bedtime, -1);
    final sunlightTime = _adjustTime(wakeTime, 3);
    final screenTime = _adjustTime(bedtime, -2);
    final type = sleepHours < targetFloor
        ? RescueType.underslept
        : (sleepHours > 9 ? RescueType.overslept : RescueType.normal);
    final checklist = _buildDynamicChecklist(
      type: type,
      energyLevel: energyLevel,
      sleepDebtMinutes: sleepDebtMinutes,
      wakeTime: wakeTime,
      bedtime: bedtime,
      napStart: napStart,
      napEnd: napEnd,
      caffeineStop: caffeineStop,
      newBedtime: newBedtime,
      sunlightTime: sunlightTime,
      screenTime: screenTime,
    );

    if (type == RescueType.underslept) {
      return RescuePlan(
        type: RescueType.underslept,
        hoursSlept: sleepHours,
        title: '${sleepHours.toStringAsFixed(1)}h slept',
        subtitle: "Below your ${targetFloor}h floor! Here's your 24h recovery plan:",
        napWindow: napStart,
        caffeineStop: caffeineStop,
        newBedtime: newBedtime,
        checklist: checklist,
      );
    } else if (type == RescueType.overslept) {
      return RescuePlan(
        type: RescueType.overslept,
        hoursSlept: sleepHours,
        title: '${sleepHours.toStringAsFixed(1)}h slept',
        subtitle: "Way above target. Let's reset your rhythm tonight:",
        checklist: checklist,
      );
    } else {
      return RescuePlan(
        type: RescueType.normal,
        hoursSlept: sleepHours,
        title: 'You are all good for today',
        subtitle: 'Your sleep rhythm looks balanced.',
        checklist: [],
      );
    }
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isNotEmpty ? text : fallback;
}

String? _extractTimeFromText(String? text) {
  if (text == null || text.trim().isEmpty) {
    return null;
  }

  final match = RegExp(r'\b\d{2}:\d{2}\b').firstMatch(text);
  return match?.group(0);
}

List<Map<String, dynamic>> _extractChecklistItems(Map<String, dynamic> data) {
  final rawItems = data['checklistItems'] ?? data['checklist'] ?? data['tasks'];
  if (rawItems is! List) {
    return [];
  }

  return rawItems
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

