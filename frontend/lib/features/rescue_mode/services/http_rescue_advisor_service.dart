import 'package:dont_forget_sleep/core/api_client.dart';
import '../models/rescue_plan_model.dart';
import 'rescue_advisor_service.dart';

class HttpRescueAdvisorService implements RescueAdvisorService {
  @override
  Future<RescuePlan> generatePlan({
    required String userId,
    required double sleepHours,
    required int energyLevel,
    required int sleepDebtMinutes,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final body = await ApiClient.postRescuePlan({
      'userId': userId,
      'currentDate': dateStr,
      'currentEnergyLevel': energyLevel,
      'currentSleepDebtMinutes': sleepDebtMinutes,
    });

    if (body['success'] == true) {
      final data = body['data'] as Map<String, dynamic>;
      return parseRescuePlan(data: data, sleepHours: sleepHours);
    }

    throw Exception(body['message'] ?? 'Failed to generate rescue plan');
  }
}
