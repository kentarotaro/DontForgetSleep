import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/features/schedule/models/schedule_planner_models.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

import 'glowing_button.dart';

class SchedulePlannerStepTwo extends StatelessWidget {
  final List<String> days;
  final List<Goal> goals;
  final Map<String, List<ScheduleBlock>> schedule;
  final List<Color> goalColors;
  final String Function(double) formatTime;
  final Color Function(ScheduleBlock) getBlockColor;
  final VoidCallback onEdit;
  final VoidCallback onComplete;

  const SchedulePlannerStepTwo({
    super.key,
    required this.days,
    required this.goals,
    required this.schedule,
    required this.goalColors,
    required this.formatTime,
    required this.getBlockColor,
    required this.onEdit,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your week', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text(
            'Sleep-protected and auto scheduled',
            style: AppTextStyles.itemMeta,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildLegendItem('Sleep', AppColors.teal),
              _buildLegendItem('Fixed', AppColors.purple800),
              ...goals.asMap().entries.map((e) => _buildLegendItem(e.value.name, goalColors[e.key % goalColors.length])),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildCalendarGrid(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.tealMuted,
                      border: Border.all(color: AppColors.teal.withOpacity(0.13)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Text('🌙', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sleep floor protected', style: AppTextStyles.itemTitle),
                              const SizedBox(height: 2),
                              Text('11 PM – 7 AM · 8 hours every night', style: AppTextStyles.itemMeta),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlowingButton(
            text: 'Complete',
            onPressed: onComplete,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: onEdit,
              child: Text('Edit', style: AppTextStyles.buttonSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.itemMeta.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    const int calStart = 6;
    const int calEnd = 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(height: 30, width: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border)))),
            ...List.generate(calEnd - calStart, (index) {
              final int hour = calStart + index;
              return Container(
                height: 36,
                width: 40,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, top: 2),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: Text(
                  hour % 3 == 0 ? formatTime(hour.toDouble()) : '',
                  style: AppTextStyles.stepLabelActive.copyWith(color: AppColors.textTertiary, fontSize: 8),
                ),
              );
            }),
          ],
        ),
        ...days.map((day) {
          return Column(
            children: [
              Container(
                height: 30,
                width: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border), left: BorderSide(color: AppColors.border))),
                child: Text(day, style: AppTextStyles.stepLabelActive.copyWith(color: AppColors.textSecondary)),
              ),
              ...List.generate(calEnd - calStart, (index) {
                final int hour = calStart + index;
                final blocks = schedule[day] ?? [];
                final block = blocks.where((b) => b.start >= calStart && (b.start.floor() == hour || (b.start >= hour && b.start < hour + 1))).firstOrNull;

                Widget content = const SizedBox();
                if (block != null) {
                  double h = (block.end - block.start) * 36 - 2;
                  if (h < 16) h = 16;
                  final Color color = getBlockColor(block);
                  content = Container(
                    height: h,
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4)],
                    ),
                    alignment: Alignment.topCenter,
                    child: Text(
                      block.type == 'sleep' ? '💤' : block.name,
                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold, height: 1.2),
                      overflow: TextOverflow.ellipsis,
                      maxLines: (h / 12).floor(),
                    ),
                  );
                }

                return Container(
                  height: 36,
                  width: 60,
                  alignment: Alignment.topLeft,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border), left: BorderSide(color: AppColors.border))),
                  child: content,
                );
              }),
            ],
          );
        }).toList(),
      ],
    );
  }
}
