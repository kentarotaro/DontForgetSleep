import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? category;
  final Color barColor;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.category,
    required this.barColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: barColor,
              boxShadow: [
                BoxShadow(
                  color: barColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null && category!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(category!, style: AppTextStyles.itemMeta.copyWith(fontSize: 12)),
                    ),
                  ),
                Text(title, style: AppTextStyles.itemTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.itemMeta),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
