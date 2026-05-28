import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'dark_input.dart';
import 'goal_chip.dart';
import 'schedule_card.dart';

class SchedulePlannerStepOne extends StatelessWidget {
  final List<Goal> goals;
  final bool showGoalForm;
  final String gName;
  final String gCategory;
  final int gDur;
  final String gFreq;
  final List<int> durations;
  final List<String> frequencies;
  final List<Color> goalColors;
  final String Function(int) formatDur;
  final VoidCallback onBack;
  final VoidCallback onGeneratePlan;
  final VoidCallback onAddGoal;
  final VoidCallback onShowGoalForm;
  final VoidCallback onHideGoalForm;
  final ValueChanged<String> onGoalNameChanged;
  final ValueChanged<int> onGoalDurationChanged;
  final ValueChanged<String> onGoalFrequencyChanged;
  final ValueChanged<int> onDeleteGoal;
  final ValueChanged<String> onGoalCategoryChanged;

  const SchedulePlannerStepOne({
    super.key,
    required this.goals,
    required this.showGoalForm,
    required this.gName,
    required this.gCategory,
    required this.gDur,
    required this.gFreq,
    required this.durations,
    required this.frequencies,
    required this.goalColors,
    required this.formatDur,
    required this.onBack,
    required this.onGeneratePlan,
    required this.onAddGoal,
    required this.onShowGoalForm,
    required this.onHideGoalForm,
    required this.onGoalNameChanged,
    required this.onGoalDurationChanged,
    required this.onGoalFrequencyChanged,
    required this.onGoalCategoryChanged,
    required this.onDeleteGoal,
  });

  @override
  Widget build(BuildContext context) {
    final bool canGenerate = goals.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your goals', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What do you want to make time for? We\'ll try to fit these around your schedule.',
            style: AppTextStyles.sectionDesc.copyWith(
              color: AppColors.purple500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView(
              children: [
                ...goals.asMap().entries.map((e) {
                  return ScheduleCard(
                    title: e.value.name,
                    subtitle:
                        '${formatDur(e.value.duration)} · ${e.value.frequency}',
                    barColor: goalColors[e.key % goalColors.length],
                    onDelete: () => onDeleteGoal(e.key),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                if (!showGoalForm)
                  GestureDetector(
                    onTap: onShowGoalForm,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.neutral800,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+ Add Goal',
                          style: AppTextStyles.itemTitle.copyWith(
                            color: AppColors.purple500,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showGoalForm)
                  _GoalForm(
                    gName: gName,
                    gCategory: gCategory,
                    gDur: gDur,
                    gFreq: gFreq,
                    durations: durations,
                    frequencies: frequencies,
                    formatDur: formatDur,
                    onNameChanged: onGoalNameChanged,
                    onCategoryChanged: onGoalCategoryChanged,
                    onDurationChanged: onGoalDurationChanged,
                    onFrequencyChanged: onGoalFrequencyChanged,
                    onCancel: onHideGoalForm,
                    onAdd: onAddGoal,
                  ),
              ],
            ),
          ),
          SecondaryButton(
            text: 'Generate Plan',
            onPressed: canGenerate ? onGeneratePlan : null,
            disabledColor: const Color(0xFF452E7B),
            disabledTextColor: const Color(0xFF7F7F7F),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: onBack,
              child: Text('Back', style: AppTextStyles.buttonSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalForm extends StatefulWidget {
  final String gName;
  final String gCategory;
  final int gDur;
  final String gFreq;
  final List<int> durations;
  final List<String> frequencies;
  final String Function(int) formatDur;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<String> onFrequencyChanged;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _GoalForm({
    required this.gName,
    required this.gCategory,
    required this.gDur,
    required this.gFreq,
    required this.durations,
    required this.frequencies,
    required this.formatDur,
    required this.onNameChanged,
    required this.onCategoryChanged,
    required this.onDurationChanged,
    required this.onFrequencyChanged,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.gCategory;
  }

  @override
  void didUpdateWidget(covariant _GoalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gCategory != widget.gCategory) {
      _selectedCategory = widget.gCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderActive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['📚 Study', '💪🏼Workout', '🧘 Meditate', '📖 Review']
                .map(
                  (p) => GoalChip(
                    label: p,
                    isSelected: _selectedCategory == p,
                    onTap: () {
                      setState(() => _selectedCategory = p);
                      widget.onCategoryChanged(p);
                      widget.onNameChanged(p);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          DarkInput(
            hintText: 'e.g. Read for fun',
            onChanged: widget.onNameChanged,
            autoFocus: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'DURATION',
            style: AppTextStyles.stepLabelActive.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.durations
                .map(
                  (d) => GoalChip(
                    label: widget.formatDur(d),
                    isSelected: widget.gDur == d,
                    onTap: () => widget.onDurationChanged(d),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'FREQUENCY',
            style: AppTextStyles.stepLabelActive.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.frequencies
                .map(
                  (f) => GoalChip(
                    label: f,
                    isSelected: widget.gFreq == f,
                    onTap: () => widget.onFrequencyChanged(f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: const BorderSide(color: AppColors.purple800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.gName.trim().isEmpty ? null : widget.onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple800,
                    disabledBackgroundColor: const Color(0xFF452E7B),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF7F7F7F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
