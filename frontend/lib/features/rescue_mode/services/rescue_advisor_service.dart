import '../models/rescue_plan_model.dart';

abstract class RescueAdvisorService {
  Future<RescuePlan> generatePlan({required double sleepHours});
}

class MockRescueAdvisorService implements RescueAdvisorService {
  @override
  Future<RescuePlan> generatePlan({required double sleepHours}) async {
    // Simulate network latency for AI response
    await Future.delayed(const Duration(milliseconds: 1500));

    if (sleepHours < 6) {
      return RescuePlan(
        type: RescueType.underslept,
        hoursSlept: sleepHours,
        title: '${sleepHours.toInt()}h slept',
        subtitle: "Below your 6h floor! Here's your 24h recovery plan:",
        napWindow: '13:00',
        caffeineStop: '14:00',
        newBedtime: '22:00',
        checklist: [ // ini nanti ambil dari ai response
          ChecklistItem(id: 'u1', text: 'Take a 20-min power nap between 13:00—14:00', isCompleted: true),
          ChecklistItem(id: 'u2', text: 'No caffeine after 14:00 today', isCompleted: true),
          ChecklistItem(id: 'u3', text: 'Move bedtime to 22:00 tonight', isCompleted: true),
          ChecklistItem(id: 'u4', text: 'Light walk after dinner for better sleep quality', isCompleted: false),
        ],
      );
    } else if (sleepHours > 9) {
      return RescuePlan(
        type: RescueType.overslept,
        hoursSlept: sleepHours,
        title: '${sleepHours.toInt()}h slept',
        subtitle: "Way above target. Let's reset your rhythm tonight:",
        checklist: [ // ini nanti ambil dari ai response
          ChecklistItem(id: 'o1', text: 'Avoid napping today to reset your clock', isCompleted: true),
          ChecklistItem(id: 'o2', text: 'Get sunlight exposure before 10:00', isCompleted: true),
          ChecklistItem(id: 'o3', text: 'Target your normal bedtime (23:00)', isCompleted: true),
          ChecklistItem(id: 'o4', text: 'Limit screen time after 21:00', isCompleted: true),
        ],
      );
    } else {
      return RescuePlan(
        type: RescueType.normal,
        hoursSlept: sleepHours,
        title: 'You are all good for today ',
        subtitle: 'Your sleep rhythm looks balanced.',
        checklist: [], // No checklist for normal mode
      );
    }
  }
}
