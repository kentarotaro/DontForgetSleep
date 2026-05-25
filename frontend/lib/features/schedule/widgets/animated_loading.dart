import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/theme/app_spacing.dart';

class AnimatedLoading extends StatefulWidget {
  const AnimatedLoading({super.key});

  @override
  State<AnimatedLoading> createState() => _AnimatedLoadingState();
}

class _AnimatedLoadingState extends State<AnimatedLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2.5),
                  ),
                ),
              ),
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: const Border(
                      top: BorderSide(color: AppColors.amber, width: 2.5),
                    ),
                  ),
                ),
              ),
              const Text(
                '🌙',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Building your plan...',
            style: AppTextStyles.itemTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Protecting your sleep floor',
            style: AppTextStyles.itemMeta,
          ),
        ],
      ),
    );
  }
}
