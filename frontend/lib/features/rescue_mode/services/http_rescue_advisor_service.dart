import 'dart:convert';
import 'package:http/http.dart' as http;
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

    final response = await http.post(
      Uri.parse('https://rescueplan-v4gtcfan5q-uc.a.run.app'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'currentDate': dateStr,
        'currentEnergyLevel': energyLevel,
        'currentSleepDebtMinutes': sleepDebtMinutes,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return parseRescuePlan(data: data, sleepHours: sleepHours);
      } else {
        throw Exception(body['message'] ?? 'Failed to generate rescue plan');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

