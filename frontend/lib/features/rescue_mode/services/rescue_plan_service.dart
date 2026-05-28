import 'package:flutter/foundation.dart';

import '../models/rescue_plan_model.dart';
import '../repositories/rescue_repository.dart';

class RescuePlanService extends ChangeNotifier {
  final RescueRepository _repository = RescueRepository();

  RescuePlan? _plan;
  bool _isLoading = false;
  double _lastSleepHours = 0;
  bool _hasLoaded = false;
  bool _needsRefresh = true;

  RescuePlan? get plan => _plan;
  bool get isLoading => _isLoading;

  Future<void> loadPlan(double sleepHours) async {
    _lastSleepHours = sleepHours;
    _isLoading = true;
    notifyListeners();

    try {
      _plan = await _repository.getRescuePlan(sleepHours);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading rescue plan: $e');
      _plan = null;
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      _needsRefresh = false;
      notifyListeners();
    }
  }

  void setPreferredSleepHours(double sleepHours) {
    final changed = (_lastSleepHours - sleepHours).abs() > 0.01;
    if (changed) {
      _lastSleepHours = sleepHours;
      _needsRefresh = true;
      return;
    }

    if (!_hasLoaded) {
      _needsRefresh = true;
    }
  }

  void markNeedsRefresh() {
    _needsRefresh = true;
  }

  Future<void> reloadIfNeeded() async {
    if (_isLoading) return;
    if (!_hasLoaded || _needsRefresh) {
      await loadPlan(_lastSleepHours);
    }
  }

  Future<void> reload() async {
    await loadPlan(_lastSleepHours);
  }

  void toggleChecklistItem(String id) {
    if (_plan == null) return;

    final updatedChecklist = _plan!.checklist.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    _plan = RescuePlan(
      type: _plan!.type,
      hoursSlept: _plan!.hoursSlept,
      title: _plan!.title,
      subtitle: _plan!.subtitle,
      checklist: updatedChecklist,
      napWindow: _plan!.napWindow,
      caffeineStop: _plan!.caffeineStop,
      newBedtime: _plan!.newBedtime,
    );
    notifyListeners();

    final completedIds = _plan!.checklist
        .where((item) => item.isCompleted)
        .map((item) => item.id)
        .toList();
    _repository.updateCompletedChecklistItems(completedIds);
  }
}

final rescuePlanService = RescuePlanService();
