import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dont_forget_sleep/features/history/data/history_service_locator.dart';
import '../../data/models/sleep_entry.dart';
import '../widgets/sleep_history_tile.dart';
import '../widgets/summary_stat_card.dart';
import '../widgets/weekly_sleep_chart.dart';
import 'sleep_detail_timeline_page.dart';

class SleepHistoryPage extends StatefulWidget {
  const SleepHistoryPage({super.key});

  @override
  State<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends State<SleepHistoryPage> {
  DateTime? _selectedDetailDate;

  void _openDetail(DateTime selectedDate) {
    setState(() {
      _selectedDetailDate = selectedDate;
    });
  }

  List<Widget> _buildWeeklySections(List<SleepEntry> entries) {
    if (entries.isEmpty) return [];

    final Map<DateTime, List<SleepEntry>> weeks = {};
    for (final e in entries) {
      final start = e.startTime;
      final monday = start.subtract(Duration(days: (start.weekday + 6) % 7));
      final key = DateTime(monday.year, monday.month, monday.day);
      weeks.putIfAbsent(key, () => []).add(e);
    }

    final sortedWeeks = weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    final List<Widget> slivers = [];
    for (final weekStart in sortedWeeks) {
      final weekEntries = weeks[weekStart]!..sort((a, b) => b.startTime.compareTo(a.startTime));
      final weekLabel = DateFormat('MMM d').format(weekStart);

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Week of $weekLabel',
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, idx) {
              final entry = weekEntries[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SleepHistoryTile(
                  entry: entry,
                  onTap: () => _openDetail(entry.startTime),
                ),
              );
            },
            childCount: weekEntries.length,
          ),
        ),
      );
    }

    return slivers;
  }

  List<double> _buildChartData(List<SleepEntry> entries) {
    final nightEntries = entries.where((entry) => entry.type == SleepType.nightSleep).toList();
    final lastSeven = nightEntries.take(7).toList().reversed.toList();
    return lastSeven.map((entry) => entry.duration.inMinutes / 60.0).toList();
  }

  List<String> _buildChartLabels(List<SleepEntry> entries) {
    final nightEntries = entries.where((entry) => entry.type == SleepType.nightSleep).toList();
    final lastSeven = nightEntries.take(7).toList().reversed.toList();
    return lastSeven.map((entry) => DateFormat('E').format(entry.endTime)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sleepHistoryService,
      builder: (context, _) {
        final entries = sleepHistoryService.entries;
        final stats = sleepHistoryService.summaryStats;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _selectedDetailDate != null
              ? SleepDetailTimelinePage(
                  key: ValueKey('detail_${_selectedDetailDate!.toIso8601String()}'),
                  date: _selectedDetailDate!,
                  onClose: () => setState(() => _selectedDetailDate = null),
                )
              : Scaffold(
                  key: const ValueKey('history_list'),
                  backgroundColor: const Color(0xFF070312),
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text(
                      'Sleep History',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  body: RefreshIndicator(
                    color: const Color(0xFF7B4DFF),
                    backgroundColor: const Color(0xFF11071F),
                    onRefresh: () => sleepHistoryService.fetchSleepHistory(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (entries.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.nights_stay_rounded,
                                    size: 80,
                                    color: const Color(0xFF7B4DFF).withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'No sleep history yet 🌙',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Start tracking your sleep to see patterns and recovery insights.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SummaryStatCard(
                                          label: 'Average sleep',
                                          value: stats['averageSleep'] ?? '-',
                                          textColor: AppColors.purple500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SummaryStatCard(
                                          label: 'Sleep consistency',
                                          value: stats['consistency'] ?? '-',
                                          textColor: const Color(0xFF00D8BF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: SummaryStatCard(
                                          label: 'Day streak',
                                          value: '${stats['dayStreak'] ?? 0} 🔥',
                                          textColor: const Color(0xFFFFBC00),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sleep Times',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  WeeklySleepChart(
                                    sleepDurations: _buildChartData(entries),
                                    dayLabels: _buildChartLabels(entries),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                              child: Text(
                                'All Sleep Times',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          ..._buildWeeklySections(entries),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
