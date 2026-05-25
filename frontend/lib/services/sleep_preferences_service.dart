import 'package:flutter/foundation.dart';

class SleepPreferencesService extends ChangeNotifier {
  int _targetSleepFloorHours = 7;
  bool _hasCompletedOnboarding = false;
  String _wakeUpTiredFrequency = '';
  String _typicalSleepAmount = '';
  List<String> _sleepAffectingHabits = [];

  int get targetSleepFloorHours => _targetSleepFloorHours;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get wakeUpTiredFrequency => _wakeUpTiredFrequency;
  String get typicalSleepAmount => _typicalSleepAmount;
  List<String> get sleepAffectingHabits => List.unmodifiable(_sleepAffectingHabits);

  void setTargetSleepFloorHours(int hours) {
    if (hours == _targetSleepFloorHours) {
      return;
    }

    _targetSleepFloorHours = hours;
    notifyListeners();
  }

  void setPersonalizationData({
    required String tiredFrequency,
    required String sleepAmount,
    required List<String> habits,
  }) {
    _wakeUpTiredFrequency = tiredFrequency;
    _typicalSleepAmount = sleepAmount;
    _sleepAffectingHabits = List.from(habits);
    notifyListeners();
  }

  void completeOnboarding() {
    if (_hasCompletedOnboarding) {
      return;
    }

    _hasCompletedOnboarding = true;
    notifyListeners();
  }
}

final sleepPreferencesService = SleepPreferencesService();