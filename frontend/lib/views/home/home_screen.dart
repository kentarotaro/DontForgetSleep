import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/features/history/models/sleep_entry.dart';
import 'package:dont_forget_sleep/features/history/services/mock_sleep_history_service.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/views/caffeine_advisor/caffeine_advisor_page.dart';
import 'package:dont_forget_sleep/features/rescue_mode/pages/rescue_mode_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSubmitted = false;
  String selectedHour = '4h';
  int selectedEnergy = 0;
  SleepEntry? lastSubmittedEntry;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sleepHistoryService,
      builder: (context, _) {
        final entries = sleepHistoryService.entries;
        final stats = sleepHistoryService.summaryStats;
        final targetFloorHours = sleepPreferencesService.targetSleepFloorHours;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  isSubmitted ? _buildSubmittedCard() : _buildCheckInCard(),
                  const SizedBox(height: 16),
                  _buildGridCards(entries, stats, targetFloorHours),
                  const SizedBox(height: 16),
                  _buildBottomActionCards(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning',
              style: TextStyle(
                color: AppColors.purple500,
                fontSize: 14,
                // fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Text(
                  'John',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text('👋', style: TextStyle(fontSize: 24)),
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
            icon: const Icon(Icons.notifications_outlined, color: Color(0xffC084FC)),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  Widget _buildCheckInCard() {
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
            children:  [
              Transform.rotate(
                angle: -0.7,
                child: Icon(Icons.nightlight_round, color: AppColors.purple300, size: 20),
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
            style: TextStyle(color:  Color(0xFFC098E9), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4h', '5h', '6h', '7h', '8h+'].map((hour) {
              final isSelected = selectedHour == hour;
              return GestureDetector(
                onTap: () => setState(() => selectedHour = hour),
                child: Container(
                  width: 50,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B236A) : const Color(0xff1C0E30),
                    borderRadius: BorderRadius.circular(5),
                    // border: Border.all(
                    //   // color: isSelected ? AppColors.bluePrimary : Colors.transparent,
                    //   width: 2,
                    // ),
                  ),
                  child: Text(
                    hour,
                    style: TextStyle(
                      color: AppColors.purple400,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Energy Level',
            style: TextStyle(color:  Color(0xFFC098E9), fontSize: 14),
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
                    color: isSelected ? const Color(0xFF372062) : const Color(0xff1C0E30),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF985DFF) : Colors.transparent,
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
              onPressed: () async {
                final now = DateTime.now();
                final sleepHours = _parseSelectedSleepHours();
                final duration = Duration(minutes: (sleepHours * 60).round());
                final entry = SleepEntry(
                  id: now.microsecondsSinceEpoch.toString(),
                  startTime: now.subtract(duration),
                  endTime: now,
                  type: SleepType.nightSleep,
                  quality: selectedEnergy == 0 ? 3 : selectedEnergy,
                  notes: 'Submitted from home check-in',
                );

                await sleepHistoryService.addSleepEntry(entry);
                if (!mounted) return;
                setState(() {
                  isSubmitted = true;
                  lastSubmittedEntry = entry;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Submit Check-in',
                style: TextStyle(
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

  Widget _buildSubmittedCard() {
    final startTime = lastSubmittedEntry?.startTime;
    final endTime = lastSubmittedEntry?.endTime;
    final startTimeLabel = startTime == null
        ? '--:--'
        : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeLabel = endTime == null
        ? '--:--'
        : '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final recordedHours = lastSubmittedEntry == null
      ? selectedHour
      : (() {
        final minutes = lastSubmittedEntry!.duration.inMinutes;
        final hours = minutes ~/ 60;
        final remainder = minutes % 60;
        return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
        })();

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
                        style: TextStyle(color: Color(0xFF00D8BF), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '$recordedHours, Energy ${selectedEnergy == 0 ? 3 : selectedEnergy}/5',
                        style: const TextStyle(color: Color(0xFF00D8BF), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You met your sleep floor!',
                  style: TextStyle(color: Colors.white, fontSize: 13),
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

  Widget _buildGridCards(List<SleepEntry> entries, Map<String, dynamic> stats, int targetFloorHours) {
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
            _buildInfoCard('Sleep Floor', '${targetFloorHours}h', latestTargetSubtitle, Color(0xFFC084FC)),
            _buildInfoCard('Streak', '$streak days', 'Keep going!', Color(0xFFFCB901)),
            _buildInfoCard('Avg Sleep', averageSleep, 'This week', AppColors.purple400),
            _buildInfoCard('Compliance', compliance, 'Last 7 days', const Color(0xFF00D8BF)),
          ],
        );
      },
    );
  }

  double _parseSelectedSleepHours() {
    return double.tryParse(selectedHour.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 7.0;
  }

  SleepEntry? _latestNightSleepEntry(List<SleepEntry> entries) {
    for (final entry in entries) {
      if (entry.type == SleepType.nightSleep) {
        return entry;
      }
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  Widget _buildInfoCard(String title, String value, String subtitle, Color valueColor) {
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

  Widget _buildBottomActionCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Parse '4h', '8h+' to double
              final hours = double.tryParse(selectedHour.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 7.0;
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
                  Icon(Icons.shield_outlined, color: Color(0xFFFF666C), size: 20),
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
                  Icon(Icons.local_cafe_outlined, color: Color(0xFF00D8BF), size: 20),
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
