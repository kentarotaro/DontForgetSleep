import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

import '../models/daily_ai_snapshot.dart';
import '../models/rescue_plan_model.dart';
import 'daily_ai_repository.dart';
import '../services/rescue_advisor_service.dart';
import '../services/http_rescue_advisor_service.dart';

class RescueRepository {
  final RescueAdvisorService _service;
  final DailyAiRepository _dailyAiRepository;

  RescueRepository({
    RescueAdvisorService? service,
    DailyAiRepository? snapshotRepository,
  })  : _service = service ?? HttpRescueAdvisorService(),
        _dailyAiRepository = snapshotRepository ?? dailyAiRepository;

  Future<RescuePlan> getRescuePlan(double sleepHours) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Fetch today's energyLevel from dailyCheckins
    int energyLevel = 3;
    try {
      final checkinSnapshot = await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();
      if (checkinSnapshot.docs.isNotEmpty) {
        energyLevel = checkinSnapshot.docs.first.data()['energyLevel'] ?? 3;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching energy level for rescue plan: $e');
    }

    // 2. Fetch today's sleep duration from sleepLogs to override placeholder if needed
    double resolvedSleepHours = sleepHours;
    try {
      final sleepLogSnapshot = await FirebaseFirestore.instance
          .collection('sleepLogs')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();
      if (sleepLogSnapshot.docs.isNotEmpty) {
        final data = sleepLogSnapshot.docs.first.data();
        final durationMinutes = data['durationMinutes'] as num?;
        if (durationMinutes != null) {
          resolvedSleepHours = durationMinutes / 60.0;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching sleep hours for rescue plan: $e');
    }

    // 3. Get target sleep floor hours
    final targetFloor = sleepPreferencesService.targetSleepFloorHours;

    // 4. Calculate sleep debt (targetFloor - resolvedSleepHours) in minutes
    final double sleepDebt = targetFloor - resolvedSleepHours;
    final int sleepDebtMinutes = sleepDebt > 0 ? (sleepDebt * 60).round() : 0;

    // 5. If sleepHours is normal (meets floor and not overslept), return local normal plan
    // to avoid unnecessary Gemini API calls.
    if (resolvedSleepHours >= targetFloor && resolvedSleepHours <= 9) {
      final sleepDiff = resolvedSleepHours - targetFloor;
      String feedback;
      if (sleepDiff == 0) {
        feedback = 'You hit your exact target sleep floor of ${targetFloor}h. Perfect!';
      } else {
        feedback = 'You slept ${resolvedSleepHours.toStringAsFixed(1)}h, which is ${(sleepDiff).toStringAsFixed(1)}h above your floor target of ${targetFloor}h. Excellent job!';
      }

      return RescuePlan(
        type: RescueType.normal,
        hoursSlept: resolvedSleepHours,
        title: 'Sleep Rhythm: Balanced',
        subtitle: feedback,
        checklist: [],
      );
    }

    // 6. Check Firestore for completed checklist item IDs for today
    List<String> completedItemIds = [];
    try {
      final checkinDoc = await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc('checkin_${user.uid}_$todayStr')
          .get();
      if (checkinDoc.exists) {
        final data = checkinDoc.data();
        if (data != null && data['completedChecklistItems'] != null) {
          completedItemIds = List<String>.from(data['completedChecklistItems']);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching completed checklist items from dailyCheckins: $e');
    }

    RescuePlan? existingPlan;
    DailyAiSnapshot? existingSnapshot;
    try {
      existingSnapshot = await _dailyAiRepository.getTodaySnapshot();
      if (existingSnapshot != null) {
        existingPlan = parseRescuePlan(
          data: existingSnapshot.raw,
          sleepHours: resolvedSleepHours,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error checking existing rescue sessions in Firestore: $e');
    }

    RescuePlan rawPlan;
    if (existingPlan != null) {
      rawPlan = existingPlan;
    } else {
      try {
        rawPlan = await _service.generatePlan(
          userId: user.uid,
          sleepHours: resolvedSleepHours,
          energyLevel: energyLevel,
          sleepDebtMinutes: sleepDebtMinutes,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Error generating rescue plan from HTTP service: $e. Falling back to local mock service.');
        rawPlan = await MockRescueAdvisorService().generatePlan(
          userId: user.uid,
          sleepHours: resolvedSleepHours,
          energyLevel: energyLevel,
          sleepDebtMinutes: sleepDebtMinutes,
        );
      }
    }

    // Map completion states from dailyCheckins
    final updatedChecklist = rawPlan.checklist.map((item) {
      return item.copyWith(isCompleted: completedItemIds.contains(item.id));
    }).toList();

    return RescuePlan(
      type: rawPlan.type,
      hoursSlept: rawPlan.hoursSlept,
      title: rawPlan.title,
      subtitle: rawPlan.subtitle,
      checklist: updatedChecklist,
      napWindow: rawPlan.napWindow,
      caffeineStop: rawPlan.caffeineStop,
      newBedtime: rawPlan.newBedtime,
    );
  }

  Future<void> updateCompletedChecklistItems(List<String> completedIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc('checkin_${user.uid}_$todayStr')
          .set({
            'userId': user.uid,
            'date': todayStr,
            'completedChecklistItems': completedIds,
          }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating completed checklist items in Firestore: $e');
    }
  }
}
