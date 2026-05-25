import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class SettingsSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Border? border;

  const SettingsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.purple950,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: child,
    );
  }
}