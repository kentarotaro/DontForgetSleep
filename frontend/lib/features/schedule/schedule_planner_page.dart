import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/animated_loading.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_header.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_one.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_two.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_zero.dart';
import 'package:dont_forget_sleep/features/schedule/services/schedule_service.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/features/history/data/history_service_locator.dart';
import 'package:dont_forget_sleep/features/history/models/sleep_entry.dart';
import 'package:dont_forget_sleep/services/notification_service.dart';

class SchedulePlannerPage extends StatefulWidget {
  const SchedulePlannerPage({super.key});

  @override
  State<SchedulePlannerPage> createState() => _SchedulePlannerPageState();
}

class _SchedulePlannerPageState extends State<SchedulePlannerPage> {
  final ScheduleService _scheduleService = ScheduleService();
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final List<String> _frequencies = ['Daily', '3×/wk', '2×/wk', '1×/wk'];
  final List<int> _durations = [15, 20, 30, 45, 60, 90, 120];
  final List<Color> _goalColors = [
    AppColors.purple800,
    AppColors.pink,
    AppColors.amber,
    AppColors.bluePrimary,
    AppColors.teal,
  ];

  int _step = 0;
  int _activeDay = 0;

  final List<Commitment> _commitments = [];
  final List<Goal> _goals = [];
  String? _aiAdvice;
  // mgecek doang
  String _planGenerationLabel = 'Waiting for AI plan';
  Color _planGenerationColor = AppColors.neutral500;
  bool _planSaved = false;

  bool _showCommitForm = false;
  bool _showGoalForm = false;
  bool _isLoadingPlan = false;

  String _cCategory = '';
  String _cName = '';
  double _cStart = 8;
  double _cEnd = 10;

  String _gName = '';
  String _gCategory = '';
  int _gDur = 30;
  String _gFreq = 'Daily';

  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    sleepPreferencesService.addListener(_onPreferencesChanged);
    _loadFromPreferences();
  }

  @override
  void dispose() {
    sleepPreferencesService.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        _loadFromPreferences();
      });
    }
  }

  void _loadFromPreferences() {
    if (sleepPreferencesService.isLoading) return;
    if (_preferencesLoaded) return;

    if (sleepPreferencesService.hasCompletedSchedule) {
      _preferencesLoaded = true;
      _step = 2;
      _isLoadingPlan = true;
      _planSaved = true;
      _planGenerationLabel = 'Schedule loaded from saved plan';
      _planGenerationColor = AppColors.teal;

      _goals.clear();
      final storedGoals = sleepPreferencesService.goals.map((g) {
        return Goal(
          name: g['name'] ?? '',
          duration: g['duration'] ?? 30,
          frequency: g['frequency'] ?? 'Daily',
        );
      }).toList();
      _goals.addAll(storedGoals);

      // Fetch commitments, Google Calendar events, and build schedule from Firestore on load
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadScheduleFromFirestore();
      });
    }
  }

  Future<void> _loadScheduleFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _isLoadingPlan = false);
      }
      return;
    }

    final dates = _scheduleService.getCurrentWeekDates();
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    try {
      final remoteGoals = await _scheduleService.loadGoals(userId: uid);
      if (remoteGoals.isNotEmpty) {
        _goals
          ..clear()
          ..addAll(remoteGoals);
      }

      // 1. Fetch commitments and goals from backend (with Firestore fallback inside service)
      final scheduleItems = await _scheduleService.getManualScheduleItems(
        userId: uid,
        dates: dates,
      );

      final Map<String, List<ScheduleBlock>> loadedSchedule = {};
      for (final day in days) {
        loadedSchedule[day] = [];
      }

      final List<Commitment> loadedCommitments = [];

      for (final data in scheduleItems) {
        final title = data['title'] ?? '';
        final startStr = data['startTime'] ?? '';
        final endStr = data['endTime'] ?? '';

        if (startStr.isNotEmpty && endStr.isNotEmpty) {
          final sLocal = DateTime.parse(startStr).toLocal();
          final eLocal = DateTime.parse(endStr).toLocal();

          final weekdayIndex = sLocal.weekday - 1;
          if (weekdayIndex >= 0 && weekdayIndex < 7) {
            final dayName = days[weekdayIndex];
            final startDouble = sLocal.hour + (sLocal.minute / 60.0);
            final endDouble = eLocal.hour + (eLocal.minute / 60.0);

            // Determine if it's a sleep block, commitment or goal
            String blockType = 'commitment';
            int goalIndex = -1;

            if (title.toLowerCase().contains('sleep')) {
              blockType = 'sleep';
            } else {
              goalIndex = _goals.indexWhere((g) => g.name == title);
              if (goalIndex != -1) {
                blockType = 'goal';
              } else {
                blockType = 'commitment';
                loadedCommitments.add(
                  Commitment(
                    name: title,
                    day: dayName,
                    category: 'Manual',
                    start: startDouble,
                    end: endDouble,
                  ),
                );
              }
            }

            loadedSchedule[dayName]!.add(
              ScheduleBlock(
                name: title,
                start: startDouble,
                end: endDouble,
                type: blockType,
                goalIndex: goalIndex,
              ),
            );
          }
        }
      }

      // 2. Fetch Google Calendar events
      final calendarEvents = await _scheduleService.getGoogleCalendarEvents(
        userId: uid,
        dates: dates,
      );

      // Merge Google Calendar events
      for (final day in days) {
        final dayEvents = calendarEvents[day] ?? [];
        loadedSchedule[day]!.addAll(dayEvents);
      }

      // Inject Sleep Floor Protected blocks dynamically from preferences
      _injectSleepBlocks(loadedSchedule);

      if (mounted) {
        setState(() {
          _commitments.clear();
          _commitments.addAll(loadedCommitments);
          _schedule = loadedSchedule;
          _aiAdvice = sleepPreferencesService.aiScheduleAdvice.isNotEmpty
              ? sleepPreferencesService.aiScheduleAdvice
              : 'Here is your saved sleep-optimized schedule.';
          _isLoadingPlan = false;
        });

        _detectAndTriggerNapNotification();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading schedule from Firestore: $e');
      if (mounted) {
        setState(() => _isLoadingPlan = false);
      }
    }
  }

  Map<String, List<ScheduleBlock>> _schedule = {};

  String _formatTime(double h) {
    final hr = h % 12 == 0 ? 12 : h % 12;
    final half = ((h % 1) * 60).round();
    final suffix = h < 12 ? 'AM' : 'PM';
    return half > 0
        ? '${hr.floor()}:${half.toString().padLeft(2, '0')} $suffix'
        : '${hr.floor()} $suffix';
  }

  String _formatDur(int m) {
    if (m >= 60) {
      return m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h${m % 60}m';
    }
    return '${m}m';
  }

  void _addCommitment() {
    if (_cName.trim().isEmpty) return;
    setState(() {
      _commitments.add(
        Commitment(
          name: _cName.trim(),
          category: _cCategory,
          day: _days[_activeDay],
          start: _cStart,
          end: _cEnd,
        ),
      );
      _showCommitForm = false;
      _cCategory = '';
      _cStart = _cEnd;
      _cEnd = (_cEnd + 2) > 23 ? 23 : _cEnd + 2;
    });
  }

  void _addGoal() {
    if (_gName.trim().isEmpty) return;
    setState(() {
      _goals.add(Goal(name: _gName.trim(), duration: _gDur, frequency: _gFreq));
      _showGoalForm = false;
    });
  }

  Future<void> _generateScheduleLocalFallback({String? reason}) async {
    final bedtimeStr = sleepPreferencesService.preferredBedtime;
    final wakeTimeStr = sleepPreferencesService.preferredWakeTime;
    final double sleepStart = _parseTimeToDouble(bedtimeStr, fallback: 23.0);
    final double sleepEnd = _parseTimeToDouble(wakeTimeStr, fallback: 7.0);
    final schedule = <String, List<ScheduleBlock>>{};

    for (var day in _days) {
      final blocks = <ScheduleBlock>[];

      for (var commitment in _commitments) {
        if (commitment.day == day) {
          blocks.add(
            ScheduleBlock(
              name: commitment.name,
              start: commitment.start,
              end: commitment.end,
              type: 'commitment',
            ),
          );
        }
      }

      schedule[day] = blocks;
    }

    _injectSleepBlocks(schedule);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final dates = _scheduleService.getCurrentWeekDates();
      try {
        final calendarEvents = await _scheduleService.getGoogleCalendarEvents(
          userId: uid,
          dates: dates,
        );
        for (final day in _days) {
          final dayEvents = calendarEvents[day] ?? [];
          schedule[day]!.addAll(dayEvents);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error integrating Google Calendar events in fallback: $e');
      }
    }

    for (int goalIndex = 0; goalIndex < _goals.length; goalIndex++) {
      final goal = _goals[goalIndex];
      const Map<String, int> freqMap = {
        'Daily': 7,
        '3×/wk': 3,
        '2×/wk': 2,
        '1×/wk': 1,
      };
      final int timesPerWeek = freqMap[goal.frequency] ?? 7;
      final double durationHours = goal.duration / 60.0;
      int placed = 0;

      for (var day in _days) {
        if (placed >= timesPerWeek) break;
        final blocks = schedule[day]!;
        final occupied = blocks
            .map((block) => [block.start, block.end])
            .toList();
        occupied.sort((a, b) => a[0].compareTo(b[0]));

        for (
          double hour = sleepEnd;
          hour <= sleepStart - durationHours;
          hour += 0.5
        ) {
          final double slotEnd = hour + durationHours;
          final bool conflict = occupied.any(
            (entry) => hour < entry[1] && slotEnd > entry[0],
          );
          if (!conflict) {
            blocks.add(
              ScheduleBlock(
                name: goal.name,
                start: hour,
                end: slotEnd,
                type: 'goal',
                goalIndex: goalIndex,
              ),
            );
            placed++;
            break;
          }
        }
      }
    }

    setState(() {
      _schedule = schedule;
      _aiAdvice =
          'AI Planner was unavailable (${reason ?? "unknown error"}). Using local fallback sleep protection.';
      _planGenerationLabel = 'Generated with local fallback';
      _planGenerationColor = AppColors.amber;
      _isLoadingPlan = false;
    });

    _detectAndTriggerNapNotification();
  }

  Future<void> _generateSchedule() async {
    setState(() {
      _isLoadingPlan = true;
      _step = 2;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingPlan = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      }
      return;
    }

    final dates = _scheduleService.getCurrentWeekDates();

    try {
      // 1. Save manual commitments to Firestore
      await _scheduleService.saveCommitmentsToFirestore(
        userId: uid,
        commitments: _commitments,
        dates: dates,
      );

      await _scheduleService.syncGoalsToApi(userId: uid, goals: _goals);

      // Force a load & self-heal to guarantee firestore schema compliance before calling the cloud function
      await sleepPreferencesService.loadFromFirestore(uid);

      // 2. Fetch AI weekly schedule plan
      final result = await _scheduleService.generateAIWeeklySchedule(
        userId: uid,
        dates: dates,
      );

      // 3. Fetch Google Calendar events from Firestore
      final calendarEvents = await _scheduleService.getGoogleCalendarEvents(
        userId: uid,
        dates: dates,
      );

      // 4. Merge them!
      final mergedSchedule =
          result['schedule'] as Map<String, List<ScheduleBlock>>;
      for (final day in _days) {
        final dayEvents = calendarEvents[day] ?? [];
        mergedSchedule[day]!.addAll(dayEvents);
      }

      // Inject Sleep Floor Protected blocks dynamically from preferences
      _injectSleepBlocks(mergedSchedule);

      if (mounted) {
        setState(() {
          _schedule = mergedSchedule;
          _aiAdvice = result['advice'] as String?;
          _planGenerationLabel = 'Generated with AI';
          _planGenerationColor = AppColors.teal;
          _isLoadingPlan = false;
        });

        _detectAndTriggerNapNotification();
      }
    } catch (e) {
      // ignore: avoid_print
      print(
        'AI Schedule generation failed: $e. Falling back to local scheduler.',
      );
      if (mounted) {
        final errMessage = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _planGenerationLabel = 'AI generation failed';
          _planGenerationColor = AppColors.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Planner error: $errMessage. Using local optimizer.',
            ),
          ),
        );
        await _generateScheduleLocalFallback(reason: errMessage);
      }
    }
  }

  Future<void> _detectAndTriggerNapNotification() async {
    // Make sure sleep history is loaded
    if (sleepHistoryService.entries.isEmpty) {
      await sleepHistoryService.fetchSleepHistory();
    }

    final targetHours = sleepPreferencesService.targetSleepFloorHours;
    final entries = sleepHistoryService.entries;
    final nightSleeps = entries
        .where((e) => e.type == SleepType.nightSleep)
        .toList();
    if (nightSleeps.isEmpty) return;

    final latestEntry = nightSleeps.first;
    final isLatestUnderslept =
        (latestEntry.duration.inMinutes / 60.0) < targetHours;

    final totalDuration = nightSleeps
        .take(7)
        .fold<Duration>(Duration.zero, (sum, e) => sum + e.duration);
    final avgHours = nightSleeps.isNotEmpty
        ? (totalDuration.inMinutes / nightSleeps.length) / 60.0
        : 0.0;
    final isAvgUnderslept = avgHours < targetHours;

    final isUnderslept = isLatestUnderslept || isAvgUnderslept;
    if (!isUnderslept) return;

    // Find a gap in the schedule of today
    final dates = _scheduleService.getCurrentWeekDates();
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // Mon = 0, Sun = 6
    if (todayIndex < 0 || todayIndex >= _days.length) return;

    final todayName = _days[todayIndex];
    final blocks = _schedule[todayName] ?? [];

    double currentFreeStart = 12.0;
    final busyIntervals = <List<double>>[];
    for (final block in blocks) {
      if (block.start < 16.0 && block.end > 12.0) {
        busyIntervals.add([block.start, block.end]);
      }
    }
    busyIntervals.sort((a, b) => a[0].compareTo(b[0]));

    double maxGap = 0.0;
    double gapStart = 12.0;
    for (final interval in busyIntervals) {
      if (interval[0] > currentFreeStart) {
        final gap = interval[0] - currentFreeStart;
        if (gap > maxGap) {
          maxGap = gap;
          gapStart = currentFreeStart;
        }
      }
      if (interval[1] > currentFreeStart) {
        currentFreeStart = interval[1];
      }
    }
    if (16.0 > currentFreeStart) {
      final gap = 16.0 - currentFreeStart;
      if (gap > maxGap) {
        maxGap = gap;
        gapStart = currentFreeStart;
      }
    }

    if (maxGap >= 0.5) {
      // 30 minutes minimum
      final canNotify = await _canShowNapNotificationToday();
      if (!canNotify) {
        return;
      }

      final durationMinutes = (maxGap * 60).round();
      final durationStr = durationMinutes >= 60
          ? '${(durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '')}h'
          : '${durationMinutes}m';

      final startHour = gapStart.floor();
      final startMinute = ((gapStart - startHour) * 60).round();
      final timeStr =
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

      // 1. Show instant notification
      await notificationService.showNapNotification(durationStr, timeStr);
      await _markNapNotificationShownToday();

      // 2. Schedule nap closing warning (15m before start)
      if (todayIndex < dates.length) {
        final dateStr = dates[todayIndex];
        final parts = dateStr.split('-');
        final yr = int.parse(parts[0]);
        final mth = int.parse(parts[1]);
        final dy = int.parse(parts[2]);
        final napStartDateTime = DateTime(yr, mth, dy, startHour, startMinute);

        await notificationService.scheduleNapClosingNotification(
          napStartTime: napStartDateTime,
        );
      }
    }
  }

  Future<bool> _canShowNapNotificationToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final docId = 'checkin_${user.uid}_$todayStr';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc(docId)
          .get();
      if (!doc.exists) return true;

      final data = doc.data();
      final lastShown = data?['lastNapNotificationDate']?.toString();
      return lastShown != todayStr;
    } catch (_) {
      return true;
    }
  }

  Future<void> _markNapNotificationShownToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final docId = 'checkin_${user.uid}_$todayStr';

    try {
      await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc(docId)
          .set({
            'userId': user.uid,
            'date': todayStr,
            'lastNapNotificationDate': todayStr,
          }, SetOptions(merge: true));
    } catch (_) {
      // ignore on best-effort write
    }
  }

  Color _getBlockColor(ScheduleBlock block) {
    if (block.type == 'sleep') return AppColors.teal;
    if (block.type == 'commitment') return AppColors.purple800;
    if (block.type == 'calendar') return AppColors.bluePrimary;

    int goalIndex = block.goalIndex;
    if (goalIndex < 0) {
      goalIndex = _goals.indexWhere((goal) => goal.name == block.name);
    }
    if (goalIndex < 0) {
      goalIndex = 0;
    }

    return _goalColors[goalIndex % _goalColors.length];
  }

  double _parseTimeToDouble(String timeStr, {double fallback = 0.0}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return hour + (minute / 60.0);
      }
    } catch (_) {}
    return fallback;
  }

  List<ScheduleBlock> _generateSleepBlocks() {
    final bedtimeStr = sleepPreferencesService.preferredBedtime;
    final wakeTimeStr = sleepPreferencesService.preferredWakeTime;

    final double bed = _parseTimeToDouble(bedtimeStr, fallback: 23.0);
    final double wake = _parseTimeToDouble(wakeTimeStr, fallback: 7.0);

    final List<ScheduleBlock> blocks = [];
    if (bed > wake) {
      // Overnight sleep (crosses midnight)
      blocks.add(
        ScheduleBlock(name: 'Sleep', start: 0.0, end: wake, type: 'sleep'),
      );
      blocks.add(
        ScheduleBlock(name: 'Sleep', start: bed, end: 24.0, type: 'sleep'),
      );
    } else if (bed < wake) {
      // Daytime sleep (does not cross midnight)
      blocks.add(
        ScheduleBlock(name: 'Sleep', start: bed, end: wake, type: 'sleep'),
      );
    }
    return blocks;
  }

  void _injectSleepBlocks(Map<String, List<ScheduleBlock>> targetSchedule) {
    final sleepBlocks = _generateSleepBlocks();
    for (final day in _days) {
      targetSchedule.putIfAbsent(day, () => []);
      // Remove any existing sleep blocks to avoid duplicates
      targetSchedule[day]?.removeWhere((block) => block.type == 'sleep');
      // Add the updated sleep blocks
      targetSchedule[day]?.addAll(sleepBlocks);
    }
  }

  Map<String, List<ScheduleBlock>> _scheduleForDisplay() {
    final displaySchedule = <String, List<ScheduleBlock>>{};
    for (final day in _days) {
      displaySchedule[day] = List<ScheduleBlock>.from(
        _schedule[day] ?? const [],
      );
    }
    _injectSleepBlocks(displaySchedule);
    return displaySchedule;
  }

  void _addCommitmentDirectly(
    String name,
    String day,
    double start,
    double end,
  ) {
    setState(() {
      _commitments.add(
        Commitment(
          name: name,
          category: 'Manual',
          day: day,
          start: start,
          end: end,
        ),
      );
    });

    // Re-trigger schedule generation to update database and call function
    _generateSchedule();
  }

  void _deleteCommitmentDirectly(
    String name,
    String day,
    double start,
    double end,
  ) {
    setState(() {
      _commitments.removeWhere(
        (c) =>
            c.name == name && c.day == day && c.start == start && c.end == end,
      );
    });

    // Re-trigger schedule generation to update database and call function
    _generateSchedule();
  }

  void _handleEmptySlotTap(String day, int hour) {
    final nameController = TextEditingController();
    double startTime = hour.toDouble();
    double endTime = (hour + 1).toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime({required bool isStart}) async {
            final currentValue = isStart ? startTime : endTime;
            final initialHour = currentValue.floor();
            final initialMinute = ((currentValue - initialHour) * 60).round();
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: true),
                child: child ?? const SizedBox.shrink(),
              ),
            );
            if (picked != null) {
              final value = picked.hour.toDouble() + picked.minute / 60.0;
              setDialogState(() {
                if (isStart) {
                  startTime = value;
                  if (endTime <= startTime) {
                    endTime = (startTime + 1).clamp(0, 24).toDouble();
                  }
                } else {
                  endTime = value;
                }
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.scaffoldBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add Commitment on $day',
              style: const TextStyle(
                color: const Color.fromARGB(255, 241, 242, 246),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Start & End Time',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Commitment Name (e.g. Class, Work)',
                    hintStyle: const TextStyle(color: AppColors.neutral_400),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.purple900),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.purple500),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelectButton(
                        label: 'Start',
                        value: startTime,
                        onTap: () => pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeSelectButton(
                        label: 'End',
                        value: endTime,
                        onTap: () => pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.purple400,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty || endTime <= startTime) return;

                        Navigator.pop(context);
                        _addCommitmentDirectly(name, day, startTime, endTime);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _TimeSelectButton({
    required String label,
    required double value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _formatTime(value),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBlockTap(ScheduleBlock block, String day) {
    final timeRange = '${_formatTime(block.start)} – ${_formatTime(block.end)}';

    String blockTypeLabel = '';
    String descriptionText = '';

    if (block.type == 'sleep') {
      blockTypeLabel = 'Protected Sleep Floor';
      descriptionText =
          'This is your protected sleep floor window to prevent sleep debt.';
    } else if (block.type == 'commitment') {
      blockTypeLabel = 'Manual Commitment';
      descriptionText = 'You added this commitment manually for this day.';
    } else if (block.type == 'calendar') {
      blockTypeLabel = 'Google Calendar Event';
      descriptionText =
          'This event is synchronized from your Google Calendar. You can edit it directly in Google Calendar.';
    } else {
      blockTypeLabel = 'AI Scheduled Goal';
      descriptionText =
          'This goal is automatically scheduled by the AI planner to optimize your energy levels.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.scaffoldBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.purple900, width: 1.5),
        ),
        title: Row(
          children: [
            Text(
              block.type == 'sleep' ? '💤' : '📅',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                block.type == 'sleep' ? 'Sleep Window' : block.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blockTypeLabel,
              style: TextStyle(
                color: block.type == 'sleep'
                    ? AppColors.teal
                    : (block.type == 'calendar'
                          ? AppColors.bluePrimary
                          : AppColors.purple400),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$day, $timeRange',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descriptionText,
              style: const TextStyle(
                color: AppColors.neutral_400,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              if (block.type == 'commitment') ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteCommitmentDirectly(
                        block.name,
                        day,
                        block.start,
                        block.end,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchedulePlannerHeader(currentStep: _step, isSaved: _planSaved),
            Flexible(
              fit: FlexFit.loose,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return SchedulePlannerStepZero(
          days: _days,
          fullDays: _fullDays,
          activeDay: _activeDay,
          commitments: _commitments,
          showCommitForm: _showCommitForm,
          cCategory: _cCategory,
          cName: _cName,
          cStart: _cStart,
          cEnd: _cEnd,
          formatTime: _formatTime,
          canContinue: _commitments.isNotEmpty,
          onContinue: () => setState(() => _step = 1),
          onAddToDay: () => setState(() {
            _showCommitForm = true;
            _cCategory = '';
            _cName = '';
            _cStart = 8;
            _cEnd = 10;
          }),
          onShowCommitForm: () => setState(() => _showCommitForm = true),
          onHideCommitForm: () => setState(() => _showCommitForm = false),
          onDaySelected: (index) => setState(() => _activeDay = index),
          onDeleteCommitment: (commitment) =>
              setState(() => _commitments.remove(commitment)),
          onCommitCategoryChanged: (value) =>
              setState(() => _cCategory = value),
          onCommitNameChanged: (value) => setState(() => _cName = value),
          onCommitStartChanged: (value) => setState(() => _cStart = value),
          onCommitEndChanged: (value) => setState(() => _cEnd = value),
          onCommitAdded: _addCommitment,
        );
      case 1:
        return SchedulePlannerStepOne(
          goals: _goals,
          showGoalForm: _showGoalForm,
          gName: _gName,
          gCategory: _gCategory,
          gDur: _gDur,
          gFreq: _gFreq,
          durations: _durations,
          frequencies: _frequencies,
          goalColors: _goalColors,
          formatDur: _formatDur,
          onBack: () => setState(() => _step = 0),
          onGeneratePlan: _generateSchedule,
          onAddGoal: _addGoal,
          onShowGoalForm: () => setState(() {
            _showGoalForm = true;
            _gName = '';
            _gCategory = '';
            _gDur = 30;
            _gFreq = 'Daily';
          }),
          onHideGoalForm: () => setState(() => _showGoalForm = false),
          onGoalNameChanged: (value) => setState(() => _gName = value),
          onGoalCategoryChanged: (value) => setState(() => _gCategory = value),
          onGoalDurationChanged: (value) => setState(() => _gDur = value),
          onGoalFrequencyChanged: (value) => setState(() => _gFreq = value),
          onDeleteGoal: (index) => setState(() => _goals.removeAt(index)),
        );
      case 2:
        final displaySchedule = _scheduleForDisplay();
        return _isLoadingPlan
            ? const AnimatedLoading()
            : SchedulePlannerStepTwo(
                days: _days,
                goals: _goals,
                schedule: displaySchedule,
                goalColors: _goalColors,
                formatTime: _formatTime,
                getBlockColor: _getBlockColor,
                sleepFloorHours: sleepPreferencesService.targetSleepFloorHours,
                preferredBedtime: sleepPreferencesService.preferredBedtime,
                preferredWakeTime: sleepPreferencesService.preferredWakeTime,
                generationLabel: _planGenerationLabel,
                generationColor: _planGenerationColor,
                aiAdvice: _aiAdvice,
                isSaved: _planSaved,
                onEdit: () => setState(() {
                  _step = 1;
                  _planSaved = false;
                }),
                onComplete: () async {
                  setState(() {
                    _planSaved = true;
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Plan saved!')));
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    final goalsList = _goals
                        .map(
                          (g) => {
                            'name': g.name,
                            'duration': g.duration,
                            'frequency': g.frequency,
                          },
                        )
                        .toList();
                    await _scheduleService.syncGoalsToApi(
                      userId: uid,
                      goals: _goals,
                    );
                    await sleepPreferencesService.updateGoals(uid, goalsList);
                    await sleepPreferencesService.completeSchedule(
                      uid,
                      advice: _aiAdvice,
                    );
                  }
                },
                onEmptySlotTap: _handleEmptySlotTap,
                onBlockTap: _handleBlockTap,
              );
      default:
        return const SizedBox();
    }
  }
}
