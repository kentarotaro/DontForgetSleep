import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/animated_loading.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_header.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_one.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_two.dart';
import 'package:dont_forget_sleep/features/schedule/widgets/schedule_planner_step_zero.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class SchedulePlannerPage extends StatefulWidget {
  const SchedulePlannerPage({super.key});

  @override
  State<SchedulePlannerPage> createState() => _SchedulePlannerPageState();
}

class _SchedulePlannerPageState extends State<SchedulePlannerPage> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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

  void _generateSchedule() {
    setState(() {
      _isLoadingPlan = true;
      _step = 2;
    });

    Timer(const Duration(milliseconds: 1400), () {
      const double sleepStart = 23.0;
      const double sleepEnd = 7.0;
      final schedule = <String, List<ScheduleBlock>>{};

      for (var day in _days) {
        final blocks = <ScheduleBlock>[];
        blocks.add(ScheduleBlock(name: 'Sleep', start: 0, end: sleepEnd, type: 'sleep'));
        blocks.add(ScheduleBlock(name: 'Sleep', start: sleepStart, end: 24, type: 'sleep'));

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

      for (int goalIndex = 0; goalIndex < _goals.length; goalIndex++) {
        final goal = _goals[goalIndex];
        const Map<String, int> freqMap = {'Daily': 7, '3×/wk': 3, '2×/wk': 2, '1×/wk': 1};
        final int timesPerWeek = freqMap[goal.frequency] ?? 7;
        final double durationHours = goal.duration / 60.0;
        int placed = 0;

        for (var day in _days) {
          if (placed >= timesPerWeek) break;
          final blocks = schedule[day]!;
          final occupied = blocks.map((block) => [block.start, block.end]).toList();
          occupied.sort((a, b) => a[0].compareTo(b[0]));

          for (double hour = sleepEnd; hour <= sleepStart - durationHours; hour += 0.5) {
            final double slotEnd = hour + durationHours;
            final bool conflict = occupied.any((entry) => hour < entry[1] && slotEnd > entry[0]);
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
        _isLoadingPlan = false;
      });
    });
  }

  Color _getBlockColor(ScheduleBlock block) {
    if (block.type == 'sleep') return AppColors.teal;
    if (block.type == 'commitment') return AppColors.purple800;
    return _goalColors[block.goalIndex % _goalColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchedulePlannerHeader(currentStep: _step),
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
          onDeleteCommitment: (commitment) => setState(() => _commitments.remove(commitment)),
          onCommitCategoryChanged: (value) => setState(() => _cCategory = value),
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
        return _isLoadingPlan
            ? const AnimatedLoading()
            : SchedulePlannerStepTwo(
                days: _days,
                goals: _goals,
                schedule: _schedule,
                goalColors: _goalColors,
                formatTime: _formatTime,
                getBlockColor: _getBlockColor,
                onEdit: () => setState(() => _step = 1),
                onComplete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan saved!')),
                  );
                },
              );
      default:
        return const SizedBox();
    }
  }
}
