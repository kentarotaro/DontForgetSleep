import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

class TimePickerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeString;
  final VoidCallback onTap;

  const TimePickerCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeString,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.purple950,
          border: Border.all(color: AppColors.purple900),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Mirror and tilt the moon icon when it's the nightlight glyph
            (() {
              if (icon == Icons.nightlight_round) {
                return Transform.scale(
                  scaleX: -1.0,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: -0.7,
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 36),
                  ),
                );
              }
              return Icon(icon, color: iconColor, size: 36);
            })(),
            const SizedBox(width: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelSecondary.copyWith(fontSize: 12,color: AppColors.purple350), 
                  ),
                  // const SizedBox(height: 0),
                  Text(
                    timeString,
                    style: AppTextStyles.authTitle.copyWith(fontSize: 24),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color:  Color(0xFF8561B5),
            ),
          ],
        ),
      ),
    );
  }
}
