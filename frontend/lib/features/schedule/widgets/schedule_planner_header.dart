import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';

class SchedulePlannerHeader extends StatelessWidget {
  final int currentStep;
  final bool isSaved;

  const SchedulePlannerHeader({
    super.key,
    required this.currentStep,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      // padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSaved) ...[
            StepProgressBar(currentStep: currentStep, totalSteps: 3),
            const SizedBox(height: 24),
            Text(
              'STEP ${currentStep + 1} OF 3',
              style: AppTextStyles.stepLabelActive.copyWith(
                color: AppColors.purple500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
