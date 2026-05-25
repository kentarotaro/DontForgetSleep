import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/sleep_entry.dart';

class SleepTimelineBlock extends StatelessWidget {
  final SleepEntry entry;
  final double hourHeight;
  final VoidCallback? onTap;
  final DateTime? visibleStart;
  final DateTime? visibleEnd;

  const SleepTimelineBlock({
    super.key,
    required this.entry,
    this.hourHeight = 60.0,
    this.onTap,
    this.visibleStart,
    this.visibleEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isNap = entry.isNap;
    final color = isNap ? const Color(0xFF00D1FF) : const Color(0xFF7B4DFF);
    final bgColor = color.withOpacity(0.15);
    final borderColor = color.withOpacity(0.5);

    final vStart = visibleStart ?? entry.startTime;
    final vEnd = visibleEnd ?? entry.endTime;
    final visibleDuration = vEnd.difference(vStart);
    final isClippedAtStart = vStart.isAfter(entry.startTime);
    final isClippedAtEnd = vEnd.isBefore(entry.endTime);
    final contextLabel = isClippedAtStart
        ? 'Continued from previous night'
        : (isClippedAtEnd ? 'Continues next day' : null);

    final height = (visibleDuration.inMinutes / 60) * hourHeight;
    final fullStartTimeStr = DateFormat('HH:mm').format(entry.startTime);
    final fullEndTimeStr = DateFormat('HH:mm').format(entry.endTime);
    final fullDuration = entry.formattedDuration;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isNap ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                    color: color,
                    size: 14,
                  ),
                  if (contextLabel != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Text(
                        contextLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (height > 50)
              Positioned(
                top: 8,
                right: 8,
                child: Text(
                  fullDuration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (height > 40)
              Positioned(
                bottom: 8,
                left: 8,
                child: Text(
                  '$fullStartTimeStr - $fullEndTimeStr',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
