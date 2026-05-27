import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/features/history/models/sleep_entry.dart';
import 'package:dont_forget_sleep/features/history/data/history_service_locator.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/views/caffeine_advisor/caffeine_advisor_page.dart';
import 'package:dont_forget_sleep/features/rescue_mode/pages/rescue_mode_page.dart';
import 'package:dont_forget_sleep/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSubmitted = false;
  bool _isSubmittingCheckIn = false;
  String selectedHour = '4h';
  int selectedEnergy = 0;
  SleepEntry? lastSubmittedEntry;
  String? customHour;

  @override
  void initState() {
    super.initState();
    sleepHistoryService.fetchSleepHistory();
  }

  void _checkAndTriggerNotifications(double sleepHours, int targetFloorHours) {
    // 1. Rescue Mode Alert
    if (sleepHours < targetFloorHours) {
      notificationService.showRescueNotification(sleepHours);
    }

    final entries = sleepHistoryService.entries;
    final nightSleeps =
        entries.where((e) => e.type == SleepType.nightSleep).toList()
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

    if (nightSleeps.isEmpty) return;

    // 2. Safety Warning: Under 4h for 3+ consecutive days (including today)
    if (nightSleeps.length >= 3) {
      final lastThreeUnder4h = nightSleeps
          .take(3)
          .every((e) => (e.duration.inMinutes / 60.0) < 4.0);
      if (lastThreeUnder4h) {
        notificationService.showSafetyNotification();
        return; // Don't trigger streak/bounce back if extreme sleep deprivation alert is shown
      }
    }

    // If today's sleep met the floor
    if (sleepHours >= targetFloorHours) {
      // 3. Bounce Back Alert: met sleep floor today after 2+ consecutive rough nights
      if (nightSleeps.length >= 3) {
        final prevTwoRough = nightSleeps
            .skip(1)
            .take(2)
            .every((e) => (e.duration.inMinutes / 60.0) < targetFloorHours);
        if (prevTwoRough) {
          notificationService.showBounceBackNotification(sleepHours);
          return; // Skip standard streak alert to avoid spamming
        }
      }

      // 4. Streak / Milestone Alerts
      final streak = sleepHistoryService.summaryStats['dayStreak'] as int? ?? 0;
      if (streak >= 3) {
        final milestones = [3, 5, 7, 14];
        final isMilestone = milestones.contains(streak);
        notificationService.showStreakNotification(
          streak,
          isMilestone: isMilestone,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sleepHistoryService,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: sleepPreferencesService,
          builder: (context, __) {
            final entries = sleepHistoryService.entries;
            final stats = sleepHistoryService.summaryStats;
            final targetFloorHours =
                sleepPreferencesService.targetSleepFloorHours;
            final currentUser = FirebaseAuth.instance.currentUser;

            // Check if user has already checked in today
            final now = DateTime.now();
            final todayStr =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

            SleepEntry? todayEntry;
            for (final entry in entries) {
              if (entry.type == SleepType.nightSleep) {
                final entryDateStr =
                    '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';
                if (entryDateStr == todayStr) {
                  todayEntry = entry;
                  break;
                }
              }
            }

            // If the database has today's entry, reset the temporary submission state
            if (todayEntry != null && isSubmitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    isSubmitted = false;
                    lastSubmittedEntry = null;
                  });
                }
              });
            }

            final showSubmitted = isSubmitted || todayEntry != null;
            final displayedEntry = todayEntry ?? lastSubmittedEntry;

            return Scaffold(
              backgroundColor: AppColors.scaffoldBg,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(currentUser),
                      const SizedBox(height: 24),
                      showSubmitted
                          ? _buildSubmittedCard(
                              displayedEntry,
                              targetFloorHours,
                            )
                          : _buildCheckInCard(entries, currentUser),
                      const SizedBox(height: 16),
                      _buildGridCards(entries, stats, targetFloorHours),
                      const SizedBox(height: 16),
                      _buildBottomActionCards(displayedEntry),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(User? currentUser) {
    final greeting = _resolveGreeting(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(color: AppColors.purple500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _resolveDisplayName(currentUser),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('👋', style: TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.purple950,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xffC084FC),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  String _resolveDisplayName(User? user) {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'User';
  }

  String _resolveGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }
    return 'Good night';
  }

  String _todayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  bool _hasCheckedInToday(List<SleepEntry> entries) {
    final todayStr = _todayKey(DateTime.now());
    for (final entry in entries) {
      if (entry.type == SleepType.nightSleep &&
          _todayKey(entry.endTime) == todayStr) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCheckInCard(List<SleepEntry> entries, User? currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.purple950,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -0.7,
                child: Icon(
                  Icons.nightlight_round,
                  color: AppColors.purple300,
                  size: 20,
                ),
              ),
              // Icon(Icons.nightlight_round, color: AppColors.purple500, size: 20),
              SizedBox(width: 8),
              Text(
                'Morning Check-in',
                style: TextStyle(
                  color: AppColors.purple500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'How long did you sleep last night?',
            style: TextStyle(color: Color(0xFFC098E9), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4h', '5h', '6h', '7h', customHour ?? '+'].map((hour) {
              final isSelected = selectedHour == hour;
              final isPlusButton = hour == '+';
              return GestureDetector(
                onTap: () async {
                  if (isPlusButton || (hour == customHour && isSelected)) {
                    final double? picked = await _showCustomDurationDialog(
                      initialValue: customHour != null
                          ? _parseDurationString(customHour!)
                          : 8.0,
                    );
                    if (picked != null) {
                      final formatted = _formatDoubleDuration(picked);
                      setState(() {
                        customHour = formatted;
                        selectedHour = formatted;
                      });
                    }
                  } else {
                    setState(() {
                      selectedHour = hour;
                    });
                  }
                },
                child: Container(
                  width: 50,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B236A)
                        : const Color(0xff1C0E30),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: isPlusButton
                      ? const Icon(
                          Icons.add,
                          color: AppColors.purple400,
                          size: 20,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hour,
                            style: TextStyle(
                              color: AppColors.purple400,
                              fontWeight: FontWeight.w800,
                              fontSize: hour.length > 3 ? 11 : 13,
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Energy Level',
            style: TextStyle(color: Color(0xFFC098E9), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final isSelected = index < selectedEnergy;
              return GestureDetector(
                onTap: () => setState(() => selectedEnergy = index + 1),
                child: Container(
                  width: 50,
                  height: 38,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF372062)
                        : const Color(0xff1C0E30),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF985DFF)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 1),
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Icon(
                        Icons.bolt,
                        color: Color(0xFFC084FC),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmittingCheckIn || _hasCheckedInToday(entries)
                  ? null
                  : () async {
                      setState(() {
                        _isSubmittingCheckIn = true;
                      });

                      final now = DateTime.now();
                      final dateStr = _todayKey(now);
                      final sleepHours = _parseSelectedSleepHours();
                      final duration = Duration(
                        minutes: (sleepHours * 60).round(),
                      );
                      final entry = SleepEntry(
                        id: 'sleep_${currentUser?.uid ?? 'anonymous'}_$dateStr',
                        startTime: now.subtract(duration),
                        endTime: now,
                        type: SleepType.nightSleep,
                        quality: selectedEnergy == 0 ? 3 : selectedEnergy,
                        notes: 'Submitted from home check-in',
                      );

                      try {
                        await sleepHistoryService.addSleepEntry(entry);

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('dailyCheckins')
                              .doc('checkin_${user.uid}_$dateStr')
                              .set({
                                'userId': user.uid,
                                'date': dateStr,
                                'energyLevel': selectedEnergy == 0
                                    ? 3
                                    : selectedEnergy,
                                'caffeineIntakeMg': 0.0,
                                'mood': 'neutral',
                                'notes': 'Submitted from home check-in',
                                'sleepDurationLastNight': sleepHours
                                    .round()
                                    .clamp(4, 8),
                                'createdAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                        }

                        // Trigger notifications based on stats
                        _checkAndTriggerNotifications(
                          sleepHours,
                          sleepPreferencesService.targetSleepFloorHours,
                        );

                        if (!mounted) return;
                        setState(() {
                          isSubmitted = true;
                          lastSubmittedEntry = entry;
                        });
                      } catch (e) {
                        // ignore: avoid_print
                        print('Error saving daily check-in to Firestore: $e');
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSubmittingCheckIn = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isSubmittingCheckIn ? 'Saving...' : 'Submit Check-in',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedCard(SleepEntry? entry, int targetFloorHours) {
    final startTime = entry?.startTime;
    final endTime = entry?.endTime;
    final startTimeLabel = startTime == null
        ? '--:--'
        : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeLabel = endTime == null
        ? '--:--'
        : '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final recordedHours = entry == null
        ? selectedHour
        : (() {
            final minutes = entry.duration.inMinutes;
            final hours = minutes ~/ 60;
            final remainder = minutes % 60;
            return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
          })();
    final metSleepFloor =
        entry != null && entry.duration.inMinutes >= targetFloorHours * 60;
    final sleepStatusText = metSleepFloor
        ? 'You met your sleep floor!'
        : 'You did not meet your sleep floor yet.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121324),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0E3A43), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: Color(0xFF00D8BF), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Checked in - ',
                        style: TextStyle(
                          color: Color(0xFF00D8BF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            '$recordedHours, Energy ${entry?.quality ?? (selectedEnergy == 0 ? 3 : selectedEnergy)}/5',
                        style: const TextStyle(
                          color: Color(0xFF00D8BF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sleepStatusText,

                  style: TextStyle(
                    color: metSleepFloor ? Colors.white : AppColors.error,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sleep window: $startTimeLabel - $endTimeLabel',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCards(
    List<SleepEntry> entries,
    Map<String, dynamic> stats,
    int targetFloorHours,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;
        final targetCardHeight = constraints.maxWidth < 360 ? 132.0 : 118.0;
        final responsiveAspectRatio = cardWidth / targetCardHeight;

        final averageSleep = stats['averageSleep'] ?? '-';
        final compliance = stats['consistency'] ?? '-';
        final streak = stats['dayStreak'] ?? 0;
        final latestNightEntry = _latestNightSleepEntry(entries);
        final latestTargetSubtitle = latestNightEntry == null
            ? 'Set in onboarding'
            : latestNightEntry.duration.inMinutes >= targetFloorHours * 60
            ? 'Target met ✓'
            : 'Need more sleep';

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: responsiveAspectRatio,
          children: [
            _buildInfoCard(
              'Sleep Floor',
              '${targetFloorHours}h',
              latestTargetSubtitle,
              Color(0xFFC084FC),
            ),
            _buildInfoCard(
              'Streak',
              '$streak days',
              'Keep going!',
              Color(0xFFFCB901),
            ),
            _buildInfoCard(
              'Avg Sleep',
              averageSleep,
              'This week',
              AppColors.purple400,
            ),
            _buildInfoCard(
              'Compliance',
              compliance,
              'Last 7 days',
              const Color(0xFF00D8BF),
            ),
          ],
        );
      },
    );
  }

  double _parseSelectedSleepHours() {
    return _parseDurationString(selectedHour);
  }

  String _formatDoubleDuration(double hours) {
    final hrs = hours.floor();
    final mins = ((hours - hrs) * 60).round();
    if (mins == 0) {
      return '${hrs}h';
    }
    return '${hrs}h ${mins}m';
  }

  double _parseDurationString(String str) {
    if (str.contains('h') && str.contains('m')) {
      final parts = str.split('h');
      final h = double.tryParse(parts[0].trim()) ?? 8.0;
      final m = double.tryParse(parts[1].replaceAll('m', '').trim()) ?? 0.0;
      return h + (m / 60.0);
    }
    final clean = str.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 8.0;
  }

  Future<double?> _showCustomDurationDialog({double initialValue = 8.0}) {
    return showDialog<double>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        double currentVal = initialValue;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final formatted = _formatDoubleDuration(currentVal);
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B26),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Custom Sleep Duration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select how long you slept last night',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        formatted,
                        style: const TextStyle(
                          color: Color(0xFFC084FC),
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: currentVal,
                        min: 1.0,
                        max: 24.0,
                        divisions: 60, // 15-minute steps
                        onChanged: (val) {
                          setStateDialog(() {
                            currentVal = val;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1h',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '24h',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF8B5CF6),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, currentVal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  SleepEntry? _latestNightSleepEntry(List<SleepEntry> entries) {
    for (final entry in entries) {
      if (entry.type == SleepType.nightSleep) {
        return entry;
      }
    }
    return null;
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String subtitle,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple950,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionCards(SleepEntry? todayEntry) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              final hours = todayEntry != null
                  ? todayEntry.duration.inMinutes / 60.0
                  : _parseSelectedSleepHours();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RescueModePage(sleepHours: hours),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xff1E0C1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff4B1E2F), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFF666C),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rescue Mode',
                    style: TextStyle(
                      color: Color(0xFFFF666C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CaffeineAdvisorPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0E3A43), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.local_cafe_outlined,
                    color: Color(0xFF00D8BF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Caffeine Advisor',
                    style: TextStyle(
                      color: Color(0xFF00D8BF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
