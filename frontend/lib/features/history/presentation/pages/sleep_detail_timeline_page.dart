import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/history_service_locator.dart';
import '../../data/models/sleep_entry.dart';
import '../widgets/add_sleep_modal.dart';
import '../widgets/sleep_timeline_block.dart';
import '../widgets/timeline_hour_indicator.dart';

class SleepDetailTimelinePage extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClose;

  const SleepDetailTimelinePage({
    super.key,
    required this.date,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${DateFormat('EEEE').format(date)} night';
    const double hourHeight = 60.0;

    return AnimatedBuilder(
      animation: sleepHistoryService,
      builder: (context, _) {
        final allEntries = sleepHistoryService.entries;
        final dayEntries = allEntries.where((e) {
          return e.startTime.day == date.day || e.endTime.day == date.day;
        }).toList();

        Duration totalSleep = Duration.zero;
        bool hasNightSleep = false;
        for (var e in dayEntries) {
          if (!e.isNap) {
            totalSleep += e.duration;
            hasNightSleep = true;
          }
        }
        final hours = totalSleep.inHours;
        final minutes = totalSleep.inMinutes.remainder(60);
        final totalSleepStr = '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';

        void showAddDialog() async {
          final newEntry = await showAddSleepDialog(
            context,
            date: date,
            hasNightSleep: hasNightSleep,
          );
          if (newEntry != null) {
            await sleepHistoryService.addSleepEntry(newEntry);
          }
        }

        void showEditDialog(SleepEntry entry) async {
          final editedEntry = await showEditSleepDialog(
            context,
            entry: entry,
          );
          if (editedEntry != null) {
            await sleepHistoryService.updateSleepEntry(editedEntry);
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF070312),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const SizedBox.shrink(),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total sleep time',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalSleepStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 25 * hourHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Stack(
                          children: [
                            const TimelineHourIndicator(
                              hourHeight: hourHeight,
                              startHour: 0,
                              endHour: 24,
                            ),
                            ...dayEntries.map((entry) {
                              final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
                              final dayEnd = DateTime(date.year, date.month, date.day, 24, 0);

                              final visibleStart = entry.startTime.isBefore(dayStart) ? dayStart : entry.startTime;
                              final visibleEnd = entry.endTime.isAfter(dayEnd) ? dayEnd : entry.endTime;

                              if (!visibleEnd.isAfter(visibleStart)) return const SizedBox.shrink();

                              final topOffset = (visibleStart.difference(dayStart).inMinutes / 60) * hourHeight;

                              return Positioned(
                                top: topOffset,
                                left: 40,
                                right: 0,
                                child: SleepTimelineBlock(
                                  entry: entry,
                                  hourHeight: hourHeight,
                                  visibleStart: visibleStart,
                                  visibleEnd: visibleEnd,
                                  onTap: () => showEditDialog(entry),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasNightSleep ? 'Naps Today' : 'Sleep & Naps Today',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: showAddDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Add Time',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.teal,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
