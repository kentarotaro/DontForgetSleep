import 'dart:async';

import 'package:dont_forget_sleep/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SleepPreferencesService extends ChangeNotifier {
  int _targetSleepFloorHours = 7;
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedSettings = false;
  String _wakeUpTiredFrequency = '';
  String _typicalSleepAmount = '';
  List<String> _sleepAffectingHabits = [];
  String _preferredWakeTime = '07:00';
  String _preferredBedtime = '23:00';
  bool _calendarConnected = false;
  bool _hasCompletedSchedule = false;
  List<Map<String, dynamic>> _goals = [];
  String _aiScheduleAdvice = '';
  bool _isLoading = false;

  bool _bedtimeReminder = true;
  bool _caffeineReminder = true;
  bool _checkinReminder = true;
  bool _rescueReminder = false;

  int get targetSleepFloorHours => _targetSleepFloorHours;
  bool get bedtimeReminder => _bedtimeReminder;
  bool get caffeineReminder => _caffeineReminder;
  bool get checkinReminder => _checkinReminder;
  bool get rescueReminder => _rescueReminder;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCompletedSettings => _hasCompletedSettings;
  String get wakeUpTiredFrequency => _wakeUpTiredFrequency;
  String get typicalSleepAmount => _typicalSleepAmount;
  List<String> get sleepAffectingHabits => List.unmodifiable(_sleepAffectingHabits);
  String get preferredWakeTime => _preferredWakeTime;
  String get preferredBedtime => _preferredBedtime;
  bool get calendarConnected => _calendarConnected;
  bool get hasCompletedSchedule => _hasCompletedSchedule;
  List<Map<String, dynamic>> get goals => _goals;
  String get aiScheduleAdvice => _aiScheduleAdvice;
  bool get isLoading => _isLoading;

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

  void completeSettings() {
    if (_hasCompletedSettings) {
      return;
    }

    _hasCompletedSettings = true;
    notifyListeners();
  }

  Future<void> loadFromFirestore(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      int retries = 0;
      while (retries < 5) {
        doc = await FirebaseFirestore.instance.collection('userProfiles').doc(uid).get();
        if (doc.exists) {
          break;
        }
        // Wait 500ms and try again, in case the profile is still being created in the background
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (doc != null && doc.exists) {
        final data = doc.data();
        if (data != null) {
          // ignore: avoid_print
          print('DEBUG: loadFromFirestore for uid: $uid. data: $data');
          _hasCompletedOnboarding = data['onboardingCompleted'] ?? false;
          _hasCompletedSettings = data['settingsCompleted'] ?? false;
          _targetSleepFloorHours = data['sleepFloorHours'] ?? data['targetSleepHours'] ?? 7;
          _wakeUpTiredFrequency = data['morningTirednessFrequency'] ?? '';
          _typicalSleepAmount = data['usualSleepDuration'] ?? '';
          _sleepAffectingHabits = List<String>.from(data['sleepHabits'] ?? []);
          _preferredWakeTime = data['preferredWakeTime'] ?? '07:00';
          _preferredBedtime = data['preferredBedtime'] ?? '23:00';
          _calendarConnected = data['calendarConnected'] ?? false;
          _hasCompletedSchedule = data['scheduleCompleted'] ?? false;
          _goals = List<Map<String, dynamic>>.from(data['goals'] ?? []);
          _aiScheduleAdvice = data['aiScheduleAdvice'] ?? '';

          _bedtimeReminder = data['bedtimeReminder'] ?? true;
          _caffeineReminder = data['caffeineReminder'] ?? true;
          _checkinReminder = data['checkinReminder'] ?? true;
          _rescueReminder = data['rescueReminder'] ?? false;

          unawaited(
            notificationService.updateScheduledReminders(
              bedtimeEnabled: _bedtimeReminder,
              bedtime: _preferredBedtime,
              caffeineEnabled: _caffeineReminder,
              wakeTime: _preferredWakeTime,
              checkinEnabled: _checkinReminder,
            ),
          );

          // Self-healing: Ensure backend fields targetSleepHours, name, and chronotype exist
          bool needsHealing = false;
          final updates = <String, dynamic>{};

          // Self-heal onboardingCompleted for old accounts
          if (!_hasCompletedOnboarding) {
            if (data.containsKey('morningTirednessFrequency') ||
                data.containsKey('chronotype') ||
                data.containsKey('usualSleepDuration') ||
                (data['sleepHabits'] != null && (data['sleepHabits'] as List).isNotEmpty)) {
              _hasCompletedOnboarding = true;
              updates['onboardingCompleted'] = true;
              needsHealing = true;
            }
          }

          // Self-heal settingsCompleted for old accounts
          if (!_hasCompletedSettings) {
            if (data.containsKey('sleepFloorHours') || data.containsKey('targetSleepHours')) {
              if (data.containsKey('preferredWakeTime') && data.containsKey('preferredBedtime')) {
                _hasCompletedSettings = true;
                _hasCompletedOnboarding = true; // If settings are complete, onboarding must be complete
                updates['onboardingCompleted'] = true;
                updates['settingsCompleted'] = true;
                needsHealing = true;
              }
            }
          }

          // Self-heal scheduleCompleted for old accounts
          if (!_hasCompletedSchedule) {
            if (_goals.isNotEmpty) {
              _hasCompletedSchedule = true;
              updates['scheduleCompleted'] = true;
              needsHealing = true;
            }
          }

          if (!data.containsKey('targetSleepHours')) {
            updates['targetSleepHours'] = _targetSleepFloorHours;
            needsHealing = true;
          }
          if (!data.containsKey('name')) {
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            updates['name'] = '$firstName $lastName'.trim();
            needsHealing = true;
          }
          if (!data.containsKey('chronotype')) {
            final freq = _wakeUpTiredFrequency.toLowerCase();
            updates['chronotype'] = freq == 'rarely' ? 'morning' : (freq == 'always' ? 'evening' : 'intermediate');
            needsHealing = true;
          }
          if (needsHealing) {
            unawaited(
              FirebaseFirestore.instance.collection('userProfiles').doc(uid).update(updates),
            );
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading sleep preferences from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSleepFloor(String uid, int hours) async {
    _targetSleepFloorHours = hours;
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        'sleepFloorHours': hours,
        'targetSleepHours': hours,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating sleep floor: $e');
    }
  }

  Future<void> updateWakeTime(String uid, String time) async {
    _preferredWakeTime = time;
    notifyListeners();

    unawaited(
      notificationService.updateScheduledReminders(
        bedtimeEnabled: _bedtimeReminder,
        bedtime: _preferredBedtime,
        caffeineEnabled: _caffeineReminder,
        wakeTime: _preferredWakeTime,
        checkinEnabled: _checkinReminder,
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        'preferredWakeTime': time,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating wake time: $e');
    }
  }

  Future<void> updateBedtime(String uid, String time) async {
    _preferredBedtime = time;
    notifyListeners();

    unawaited(
      notificationService.updateScheduledReminders(
        bedtimeEnabled: _bedtimeReminder,
        bedtime: _preferredBedtime,
        caffeineEnabled: _caffeineReminder,
        wakeTime: _preferredWakeTime,
        checkinEnabled: _checkinReminder,
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        'preferredBedtime': time,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating bedtime: $e');
    }
  }

  Future<void> completeSchedule(String uid, {String? advice}) async {
    _hasCompletedSchedule = true;
    if (advice != null) {
      _aiScheduleAdvice = advice;
    }
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        'scheduleCompleted': true,
        if (advice != null) 'aiScheduleAdvice': advice,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error completing schedule: $e');
    }
  }

  Future<void> updateGoals(String uid, List<Map<String, dynamic>> goalsList) async {
    _goals = goalsList;
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        'goals': goalsList,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating goals: $e');
    }
  }

  Future<void> updateNotificationSettings({
    required String uid,
    bool? bedtime,
    bool? caffeine,
    bool? checkin,
    bool? rescue,
  }) async {
    if (bedtime != null) {
      _bedtimeReminder = bedtime;
      if (bedtime) {
        unawaited(notificationService.showInstantNotification(
          id: 1,
          title: '🛏️ Bedtime Reminder Active',
          body: 'We will remind you daily to protect your sleep floor.',
        ));
      }
    }
    if (caffeine != null) {
      _caffeineReminder = caffeine;
      if (caffeine) {
        unawaited(notificationService.showInstantNotification(
          id: 2,
          title: '☕ Caffeine Cutoff Active',
          body: 'We will alert you daily when it is time to stop caffeine intake.',
        ));
      }
    }
    if (checkin != null) {
      _checkinReminder = checkin;
      if (checkin) {
        unawaited(notificationService.showInstantNotification(
          id: 3,
          title: '☀️ Daily Check-in Active',
          body: 'We will remind you to check-in and log your sleep every morning.',
        ));
      }
    }
    if (rescue != null) {
      _rescueReminder = rescue;
    }
    notifyListeners();

    unawaited(
      notificationService.updateScheduledReminders(
        bedtimeEnabled: _bedtimeReminder,
        bedtime: _preferredBedtime,
        caffeineEnabled: _caffeineReminder,
        wakeTime: _preferredWakeTime,
        checkinEnabled: _checkinReminder,
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('userProfiles').doc(uid).set({
        if (bedtime != null) 'bedtimeReminder': bedtime,
        if (caffeine != null) 'caffeineReminder': caffeine,
        if (checkin != null) 'checkinReminder': checkin,
        if (rescue != null) 'rescueReminder': rescue,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating notification settings: $e');
    }
  }

  void reset() {
    _targetSleepFloorHours = 7;
    _hasCompletedOnboarding = false;
    _hasCompletedSettings = false;
    _wakeUpTiredFrequency = '';
    _typicalSleepAmount = '';
    _sleepAffectingHabits = [];
    _preferredWakeTime = '07:00';
    _preferredBedtime = '23:00';
    _calendarConnected = false;
    _hasCompletedSchedule = false;
    _goals = [];
    _aiScheduleAdvice = '';
    _isLoading = false;
    _bedtimeReminder = true;
    _caffeineReminder = true;
    _checkinReminder = true;
    _rescueReminder = false;
    unawaited(notificationService.cancelAllNotifications());
    notifyListeners();
  }
}

final sleepPreferencesService = SleepPreferencesService();