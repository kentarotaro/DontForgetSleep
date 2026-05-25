import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:flutter/material.dart';

class WeeklySleepChart extends StatelessWidget {
  final List<double> sleepDurations;
  final List<String> dayLabels;

  const WeeklySleepChart({
    super.key,
    required this.sleepDurations,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    double maxSleep = sleepDurations.isEmpty ? 10.0 : sleepDurations.reduce((a, b) => a > b ? a : b);
    maxSleep = maxSleep < 10.0 ? 10.0 : maxSleep + 2.0;
    final double averageSleep = sleepDurations.isEmpty
        ? 0.0
        : sleepDurations.reduce((a, b) => a + b) / sleepDurations.length;
    final String averageLabel = '${averageSleep.toStringAsFixed(1)}h';
    final double averageBottom = (averageSleep / maxSleep) * 120 + 24;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.purple950,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Days',
            style: TextStyle(
              color: AppColors.purple800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: averageBottom,
                  left: 0,
                  right: 36,
                  child: const _DashedAverageLine(),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(sleepDurations.length, (index) {
                      final duration = sleepDurations[index];
                      final isToday = index == sleepDurations.length - 1;
                      return _BarItem(
                        duration: duration,
                        maxDuration: maxSleep,
                        label: dayLabels[index],
                        isToday: isToday,
                      );
                    }),
                  ),
                ),
                Positioned(
                  bottom: averageBottom - 6,
                  right: 0,
                  child: Text(
                    averageLabel,
                    style: const TextStyle(
                      color: Color(0xFFB376E6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedAverageLine extends StatelessWidget {
  const _DashedAverageLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dashWidth = 4;
        const double dashGap = 4;
        final int dashCount = (constraints.maxWidth / (dashWidth + dashGap)).floor();

        return Row(
          children: List.generate(dashCount, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index == dashCount - 1 ? 0 : dashGap),
              child: Container(
                width: dashWidth,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _BarItem extends StatelessWidget {
  final double duration;
  final double maxDuration;
  final String label;
  final bool isToday;

  const _BarItem({
    required this.duration,
    required this.maxDuration,
    required this.label,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final double height = (duration / maxDuration) * 120;
    final Color barColor = duration < 7.0 ? const Color(0xFFFF666C) : const Color(0xFF8B5CF6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${duration.toStringAsFixed(1)}h',
          style: TextStyle(
            color: isToday ? Colors.white : const Color(0xFFCA82FF),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: height),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              width: 32,
              height: value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: barColor,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isToday ? Colors.white : const Color(0xff865CBC),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
