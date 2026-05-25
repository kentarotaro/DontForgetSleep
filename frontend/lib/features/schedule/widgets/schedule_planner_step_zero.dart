import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';

import 'dark_input.dart';
import 'goal_chip.dart';
import 'schedule_card.dart';

class SchedulePlannerStepZero extends StatelessWidget {
  final List<String> days;
  final List<String> fullDays;
  final int activeDay;
  final List<Commitment> commitments;
  final bool showCommitForm;
  final String cCategory;
  final String cName;
  final double cStart;
  final double cEnd;
  final String Function(double) formatTime;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onAddToDay;
  final VoidCallback onShowCommitForm;
  final VoidCallback onHideCommitForm;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<Commitment> onDeleteCommitment;
  final ValueChanged<String> onCommitCategoryChanged;
  final ValueChanged<String> onCommitNameChanged;
  final ValueChanged<double> onCommitStartChanged;
  final ValueChanged<double> onCommitEndChanged;
  final VoidCallback onCommitAdded;

  const SchedulePlannerStepZero({
    super.key,
    required this.days,
    required this.fullDays,
    required this.activeDay,
    required this.commitments,
    required this.showCommitForm,
    required this.cCategory,
    required this.cName,
    required this.cStart,
    required this.cEnd,
    required this.formatTime,
    required this.canContinue,
    required this.onContinue,
    required this.onAddToDay,
    required this.onShowCommitForm,
    required this.onHideCommitForm,
    required this.onDaySelected,
    required this.onDeleteCommitment,
    required this.onCommitCategoryChanged,
    required this.onCommitNameChanged,
    required this.onCommitStartChanged,
    required this.onCommitEndChanged,
    required this.onCommitAdded,
  });

  @override
  Widget build(BuildContext context) {
    final dayKey = days[activeDay];
    final items = commitments.where((c) => c.day == dayKey).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your week', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap a day and add what\'s locked in — classes, work, anything fixed.',
              style: AppTextStyles.sectionDesc.copyWith(
                color: AppColors.purple500,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: List.generate(days.length, (index) {
                final isAct = activeDay == index;
                final hasItems = commitments.any((c) => c.day == days[index]);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      onDaySelected(index);
                      onHideCommitForm();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: index == days.length - 1 ? 0 : 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isAct ? AppColors.primaryMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isAct ? AppColors.purple500 : AppColors.neutral800, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            days[index],
                            style: AppTextStyles.stepLabelActive.copyWith(
                              color: isAct ? AppColors.purple500 : AppColors.neutral500,
                              fontWeight: isAct ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (hasItems) const SizedBox(height: 3),
                          if (hasItems)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAct ? AppColors.purple500 : AppColors.neutral500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(fullDays[activeDay], style: AppTextStyles.itemTitle.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.md),
            ...items.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ScheduleCard(
                  title: e.value.name,
                  category: e.value.category,
                  subtitle: '${formatTime(e.value.start)} – ${formatTime(e.value.end)}',
                  barColor: AppColors.purple500,
                  onDelete: () => onDeleteCommitment(e.value),
                ),
              );
            }),
            if (items.isEmpty && !showCommitForm)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral800, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text('${fullDays[activeDay]} is empty', style: AppTextStyles.itemMeta),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (!showCommitForm)
              GestureDetector(
                onTap: onAddToDay,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.neutral800),
                  ),
                  child: Center(
                    child: Text(
                      '+ Add to ${fullDays[activeDay]}',
                      style: AppTextStyles.itemTitle.copyWith(color: AppColors.purple500),
                    ),
                  ),
                ),
              ),
            if (showCommitForm)
              _CommitmentForm(
                cCategory: cCategory,
                cName: cName,
                cStart: cStart,
                cEnd: cEnd,
                formatTime: formatTime,
                onCategoryChanged: onCommitCategoryChanged,
                onNameChanged: onCommitNameChanged,
                onStartChanged: onCommitStartChanged,
                onEndChanged: onCommitEndChanged,
                onCancel: onHideCommitForm,
                onAdd: onCommitAdded,
              ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              text: 'Continue',
              onPressed: canContinue ? onContinue : null,
              disabledColor: const Color(0xFF452E7B),
              disabledTextColor: const Color(0xFF7F7F7F),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _CommitmentForm extends StatefulWidget {
  final String cCategory;
  final String cName;
  final double cStart;
  final double cEnd;
  final String Function(double) formatTime;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _CommitmentForm({
    required this.cCategory,
    required this.cName,
    required this.cStart,
    required this.cEnd,
    required this.formatTime,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  State<_CommitmentForm> createState() => _CommitmentFormState();
}

class _CommitmentFormState extends State<_CommitmentForm> {
  late final TextEditingController _controller;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cName);
    _selectedCategory = widget.cCategory;
  }

  @override
  void didUpdateWidget(covariant _CommitmentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cName != widget.cName) {
      // keep controller in sync when parent updates cName (e.g., preset tapped)
      _controller.text = widget.cName;
      // move cursor to end
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
    if (oldWidget.cCategory != widget.cCategory) {
      _selectedCategory = widget.cCategory;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            children: ['📚 Class','💼 Work','🧪 Lab','🏃🏼 Practice']
                .map((p) => PresetChip(label: p, isSelected: _selectedCategory == p, onTap: () {
                      setState(() => _selectedCategory = p);
                      widget.onCategoryChanged(p);
                    }))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          DarkInput(hintText: "What's happening?", controller: _controller, onChanged: widget.onNameChanged, autoFocus: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TimePickerField(
                  label: 'FROM',
                  value: widget.cStart,
                  formatTime: widget.formatTime,
                  onPicked: (v) => widget.onStartChanged(v),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimePickerField(
                  label: 'TO',
                  value: widget.cEnd,
                  formatTime: widget.formatTime,
                  onPicked: (v) => widget.onEndChanged(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    backgroundColor:  Colors.black,
                    side: const BorderSide(color: AppColors.purple800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.cName.trim().isEmpty ? null : widget.onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple800,
                    disabledBackgroundColor: const Color(0xFF452E7B),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF7F7F7F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _TimePickerField extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) formatTime;
  final ValueChanged<double> onPicked;

  const _TimePickerField({
    Key? key,
    required this.label,
    required this.value,
    required this.formatTime,
    required this.onPicked,
  }) : super(key: key);

  Future<void> _pickTime(BuildContext context) async {
    final initialHour = value.floor();
    final initialMinute = ((value - initialHour) * 60).round();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      onPicked(picked.hour.toDouble() + picked.minute / 60.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.stepLabelActive.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _pickTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(formatTime(value), style: AppTextStyles.itemTitle.copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
                // const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
