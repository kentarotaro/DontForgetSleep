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
  final int sleepFloorHours;
  final String preferredBedtime;
  final String preferredWakeTime;
  final String generationLabel;
  final Color generationColor;
  final String? aiAdvice;
  final bool isSaved;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final Function(String day, int hour)? onEmptySlotTap;
  final Function(ScheduleBlock block, String day)? onBlockTap;

  const SchedulePlannerStepTwo({
    super.key,
    required this.days,
    required this.goals,
    required this.schedule,
    required this.goalColors,
    required this.formatTime,
    required this.getBlockColor,
    required this.sleepFloorHours,
    required this.preferredBedtime,
    required this.preferredWakeTime,
    required this.generationLabel,
    required this.generationColor,
    this.aiAdvice,
    this.isSaved = false,
    required this.onEdit,
    required this.onComplete,
    this.onEmptySlotTap,
    this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final String sectionTitle = isSaved ? 'Schedule' : 'Your week';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sectionTitle, style: AppTextStyles.sectionTitle),
          if (!isSaved) ...[
            const SizedBox(height: 4),
            const Text(
              'Sleep-protected and auto scheduled',
              style: AppTextStyles.itemMeta,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: generationColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: generationColor.withOpacity(0.35)),
            ),
            child: Text(
              generationLabel,
              style: AppTextStyles.itemMeta.copyWith(color: generationColor),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildLegendItem('Sleep', AppColors.teal),
              _buildLegendItem('Fixed', AppColors.purple800),
              _buildLegendItem('Calendar 📅', AppColors.bluePrimary),
              ...goals.asMap().entries.map(
                (e) => _buildLegendItem(
                  e.value.name,
                  goalColors[e.key % goalColors.length],
                ),
              ),
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
                      border: Border.all(
                        color: AppColors.teal.withOpacity(0.13),
                      ),
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
                              Text(
                                'Sleep floor protected',
                                style: AppTextStyles.itemTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$preferredBedtime – $preferredWakeTime · $sleepFloorHours hours every night',
                                style: AppTextStyles.itemMeta,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // if (aiAdvice != null && aiAdvice!.isNotEmpty) ...[
                  //   const SizedBox(height: AppSpacing.md),
                  //   Container(
                  //     padding: const EdgeInsets.all(AppSpacing.lg),
                  //     decoration: BoxDecoration(
                  //       gradient: const LinearGradient(
                  //         colors: [Color(0xFF2E1A47), Color(0xFF130B24)],
                  //         begin: Alignment.topLeft,
                  //         end: Alignment.bottomRight,
                  //       ),
                  //       border: Border.all(
                  //         color: AppColors.purple500.withOpacity(0.4),
                  //         width: 1,
                  //       ),
                  //       borderRadius: BorderRadius.circular(18),
                  //     ),
                  //     // child: Row(
                  //     //   crossAxisAlignment: CrossAxisAlignment.start,
                  //     //   children: [
                  //     //     const Text('✨', style: TextStyle(fontSize: 24)),
                  //     //     const SizedBox(width: AppSpacing.md),
                  //     //     Expanded(
                  //     //       child: Column(
                  //     //         crossAxisAlignment: CrossAxisAlignment.start,
                  //     //         children: [
                  //     //           Text(
                  //     //             'AI Sleep Window Advice',
                  //     //             style: AppTextStyles.itemTitle.copyWith(
                  //     //               color: AppColors.purple300,
                  //     //               fontWeight: FontWeight.bold,
                  //     //             ),
                  //     //           ),
                  //     //           const SizedBox(height: 6),
                  //     //           Text(
                  //     //             aiAdvice!,
                  //     //             style: AppTextStyles.itemMeta.copyWith(
                  //     //               color: Colors.white.withOpacity(0.9),
                  //     //               height: 1.4,
                  //     //             ),
                  //     //           ),
                  //     //         ],
                  //     //       ),
                  //     //     ),
                  //     //   ],
                  //     // ),
                  //   ),
                  // ],
                ],
              ),
            ),
          ),
          if (!isSaved) ...[
            const SizedBox(height: AppSpacing.md),
            GlowingButton(text: 'Complete', onPressed: onComplete),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: onEdit,
                child: Text('Edit', style: AppTextStyles.buttonSecondary),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            GlowingButton(text: 'Edit Plan', onPressed: onEdit),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.itemMeta.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    const int calStart = 4;
    const int calEnd = 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              width: 40,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
            ),
            ...List.generate(calEnd - calStart, (index) {
              final int hour = calStart + index;
              return Container(
                height: 36,
                width: 40,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, top: 2),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Text(
                  formatTime(hour.toDouble()),
                  style: AppTextStyles.stepLabelActive.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 8,
                  ),
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
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                    left: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(
                  day,
                  style: AppTextStyles.stepLabelActive.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                height: (calEnd - calStart) * 36.0,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Grid background lines & InkWell for empty slots
                    Column(
                      children: List.generate(calEnd - calStart, (index) {
                        final int hour = calStart + index;
                        return Container(
                          height: 36,
                          width: 60,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                              left: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onEmptySlotTap?.call(day, hour),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Positioned event blocks
                    ...((schedule[day] ?? [])
                        .where((b) => b.end > calStart && b.start < calEnd)
                        .map((block) {
                          final double effectiveStart = block.start < calStart
                              ? calStart.toDouble()
                              : block.start;
                          final double effectiveEnd = block.end > calEnd
                              ? calEnd.toDouble()
                              : block.end;

                          final double top = (effectiveStart - calStart) * 36.0;
                          double height =
                              (effectiveEnd - effectiveStart) * 36.0;
                          if (height < 16) height = 16;

                          final Color color = getBlockColor(block);
                          return Positioned(
                            top: top,
                            height: height,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => onBlockTap?.call(block, day),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                  vertical: 1,
                                ),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.topCenter,
                                child: Text(
                                  block.type == 'sleep' ? '💤' : block.name,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: (height / 12).floor().clamp(1, 10),
                                ),
                              ),
                            ),
                          );
                        })),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
