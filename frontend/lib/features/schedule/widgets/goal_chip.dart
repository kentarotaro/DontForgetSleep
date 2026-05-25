import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';

class GoalChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : AppColors.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.purple500 : AppColors.border,
            width: 1.5,
          ),
          // boxShadow: isSelected
          //     ? [
          //         BoxShadow(
          //           color: AppColors.primaryGlow,
          //           // blurRadius: 12,
          //           // spreadRadius: -2,
          //         )
          //       ]
          //     : [],
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonSecondary.copyWith(
            color: isSelected ? AppColors.purple500 : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.purple500 : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.itemTitle.copyWith(
            fontSize: 12,
            color: isSelected ? AppColors.purple500 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
