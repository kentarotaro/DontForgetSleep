import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep; // 0-indexed: 0 is step 1, 1 is step 2, etc.
  final int totalSteps;
  final Color filledColor;
  final Color unfilledColor;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.filledColor = AppColors.purple500,
    this.unfilledColor = AppColors.purple950,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        // If currentStep is >= index, the bar is filled.
        final bool isFilled = index <= currentStep;
        
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index == totalSteps - 1 ? 0 : 8.0,
            ),
            decoration: BoxDecoration(
              color: isFilled ? filledColor : unfilledColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
