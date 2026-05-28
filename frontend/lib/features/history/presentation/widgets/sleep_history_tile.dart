import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/sleep_entry.dart';

class SleepHistoryTile extends StatelessWidget {
  final SleepEntry entry;
  final VoidCallback onTap;

  const SleepHistoryTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startDay = DateFormat('EEEE').format(entry.startTime);
    final now = DateTime.now();
    final isYesterday = now.difference(entry.endTime).inDays == 0 && now.day != entry.endTime.day;
    final title = isYesterday ? 'Last night ($startDay)' : '$startDay night';

    final startTimeStr = DateFormat('HH:mm').format(entry.startTime);
    final endTimeStr = DateFormat('HH:mm').format(entry.endTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFF7B4DFF).withOpacity(0.2),
      highlightColor: const Color(0xFF7B4DFF).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (entry.isNap)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D1FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.5)),
                          ),
                          child: const Text(
                            'NAP',
                            style: TextStyle(
                              color: Color(0xFF00D1FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          entry.isNap ? '$startDay nap' : title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$startTimeStr - $endTimeStr',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  entry.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
