import '../models/rescue_plan_model.dart';
import '../services/rescue_advisor_service.dart';

class RescueRepository {
  final RescueAdvisorService _service;

  RescueRepository({RescueAdvisorService? service})
      : _service = service ?? MockRescueAdvisorService();

  Future<RescuePlan> getRescuePlan(double sleepHours) async {
    return await _service.generatePlan(sleepHours: sleepHours);
  }
}
