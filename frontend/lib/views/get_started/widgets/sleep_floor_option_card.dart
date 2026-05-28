import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

class SleepFloorOptionCard extends StatelessWidget {
  final String hours;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SleepFloorOptionCard({
    super.key,
    required this.hours,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color:  AppColors.purple950,
          border: Border.all(
            color: isSelected ? AppColors.purple500 : AppColors.purple900,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hours,
              style: AppTextStyles.authTitle.copyWith(
                fontSize: 32,
                color: isSelected ?  AppColors.purple500 :  AppColors.purple400,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelSecondary.copyWith(
                fontSize: 12,
                color: isSelected ? AppColors.purple400 : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
