import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.purple400,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}