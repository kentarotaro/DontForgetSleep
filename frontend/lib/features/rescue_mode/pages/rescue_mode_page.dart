import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/features/rescue_mode/models/rescue_plan_model.dart';
import 'package:dont_forget_sleep/features/rescue_mode/services/rescue_plan_service.dart';
import 'package:dont_forget_sleep/features/rescue_mode/widgets/rescue_summary_card.dart';
import 'package:dont_forget_sleep/features/rescue_mode/widgets/recovery_stat_card.dart';
import 'package:dont_forget_sleep/features/rescue_mode/widgets/checklist_tile.dart';
import 'package:dont_forget_sleep/features/rescue_mode/widgets/glowing_status_widget.dart';
import 'package:dont_forget_sleep/features/rescue_mode/widgets/rescue_toggle_tab.dart';
import 'package:dont_forget_sleep/navbar.dart';
import 'package:dont_forget_sleep/features/history/data/history_service_locator.dart';
import 'package:dont_forget_sleep/features/history/models/sleep_entry.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';

class RescueModePage extends StatefulWidget {
  final double sleepHours;

  const RescueModePage({Key? key, required this.sleepHours}) : super(key: key);

  @override
  State<RescueModePage> createState() => _RescueModePageState();
}

class _RescueModePageState extends State<RescueModePage> {
  bool _isCheckingInStatus = true;
  bool _hasCheckedInToday = false;

  @override
  void initState() {
    super.initState();
    rescuePlanService.addListener(_onServiceChanged);
    sleepHistoryService.addListener(_onSleepHistoryChanged);
    _loadCheckInStatus();

    // If the page was created without a provided sleepHours (e.g. opened from
    // the bottom navigation), try to resolve today's actual sleep entry from
    // the local sleep history service. This prevents showing `0.0h slept` when
    // a check-in or sleep log exists.
    Future.microtask(() async {
      double initialHours = widget.sleepHours;
      if (initialHours <= 0) {
        try {
          final entries = sleepHistoryService.entries;
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          for (final entry in entries) {
            if (entry.type == SleepType.nightSleep) {
              final entryDateStr =
                  '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';
              if (entryDateStr == todayStr) {
                initialHours = entry.duration.inMinutes / 60.0;
                break;
              }
            }
          }
        } catch (_) {
          // ignore and keep fallback
        }
      }

      // Ensure service has the preferred hours set and load the plan.
      rescuePlanService.setPreferredSleepHours(initialHours);
      if (!rescuePlanService.isLoading) {
        await rescuePlanService.loadPlan(initialHours);
      }
    });
  }

  @override
  void dispose() {
    rescuePlanService.removeListener(_onServiceChanged);
    sleepHistoryService.removeListener(_onSleepHistoryChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSleepHistoryChanged() {
    if (!mounted) return;

    double todayHours = 0.0;
    try {
      final entries = sleepHistoryService.entries;
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      for (final entry in entries) {
        if (entry.type == SleepType.nightSleep) {
          final entryDateStr =
              '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';
          if (entryDateStr == todayStr) {
            todayHours = entry.duration.inMinutes / 60.0;
            break;
          }
        }
      }
    } catch (_) {}

    final plan = rescuePlanService.plan;
    if (plan == null || (plan.hoursSlept - todayHours).abs() > 0.01) {
      rescuePlanService.loadPlan(todayHours);
    } else {
      setState(() {});
    }
  }

  bool get _hasCheckedInTodayLocal {
    if (_hasCheckedInToday) return true;

    try {
      final entries = sleepHistoryService.entries;
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (final entry in entries) {
        if (entry.type == SleepType.nightSleep) {
          final entryDateStr =
              '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';
          if (entryDateStr == todayStr) {
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  Future<void> _loadCheckInStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _isCheckingInStatus = false;
        });
        return;
      }

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final checkinId = 'checkin_${uid}_$todayStr';

      final checkinDoc = await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc(checkinId)
          .get();

      if (!mounted) return;
      setState(() {
        _isCheckingInStatus = false;
        if (checkinDoc.exists) {
          _hasCheckedInToday = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingInStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = rescuePlanService.plan;
    final isLoading = rescuePlanService.isLoading;
    final checkedIn = _hasCheckedInTodayLocal;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            final navController = HomeNavController.of(context);
            if (navController != null) {
              navController.goToTab(0);
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Rescue Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isCheckingInStatus
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF9151F5)),
              )
            : !checkedIn
            ? _buildCheckInEmptyState()
            : isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF9151F5)),
              )
            : plan == null
            ? const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : _buildContent(plan),
      ),
    );
  }

  Widget _buildCheckInEmptyState() {
    return RefreshIndicator(
      color: const Color(0xFF7B4DFF),
      backgroundColor: const Color(0xFF11071F),
      onRefresh: _loadCheckInStatus,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: const Color(0xFF7B4DFF).withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No rescue plan yet',
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
                      'Complete today\'s check-in from Home to unlock your personalized rescue guidance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RescuePlan plan) {
    if (plan.type == RescueType.normal) {
      return _buildNormalContent(plan);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RescueToggleTab(type: plan.type),
          const SizedBox(height: 24),
          _buildRecoveryPlan(plan),
        ],
      ),
    );
  }

  Widget _buildNormalContent(RescuePlan plan) {
    final wakeTime = sleepPreferencesService.preferredWakeTime;
    final bedtime = sleepPreferencesService.preferredBedtime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowingStatusWidget(title: plan.title, subtitle: plan.subtitle),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171427),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2541), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personalized Daily Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Steady Wake-up Time',
                  subtitle:
                      'Try to wake up around your preferred time ($wakeTime) tomorrow to keep your biological clock in sync.',
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.local_cafe_outlined,
                  title: 'Caffeine Timing',
                  subtitle:
                      'Caffeine is fine, but try to stop intake at least 8-10 hours before your bedtime ($bedtime) to ensure sleep quality.',
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.bedtime_outlined,
                  title: 'Protect Your Sleep Window',
                  subtitle:
                      'Consistent sleep is key. Prepare to wind down and target your preferred bedtime of $bedtime tonight.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalTip({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1A31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00E676), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryPlan(RescuePlan plan) {
    final completedCount = plan.checklist.where((i) => i.isCompleted).length;
    final totalCount = plan.checklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RescueSummaryCard(plan: plan),
        const SizedBox(height: 16),

        if (plan.type == RescueType.underslept)
          Row(
            children: [
              Expanded(
                child: RecoveryStatCard(
                  time: plan.napWindow ?? '-',
                  label: 'Nap window',
                  timeColor: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RecoveryStatCard(
                  time: plan.caffeineStop ?? '-',
                  label: 'Caffeine stop',
                  timeColor: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RecoveryStatCard(
                  time: plan.newBedtime ?? '-',
                  label: 'New bedtime',
                  timeColor: const Color(0xFFB388FF),
                ),
              ),
            ],
          ),

        if (plan.type == RescueType.underslept) const SizedBox(height: 32),
        if (plan.type == RescueType.overslept) const SizedBox(height: 24),

        Text(
          'RECOVERY CHECKLIST ($completedCount/$totalCount DONE)',
          style: const TextStyle(
            color: AppColors.purple300,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        ...plan.checklist.map(
          (item) => ChecklistTile(
            item: item,
            onToggle: () => rescuePlanService.toggleChecklistItem(item.id),
          ),
        ),

        const SizedBox(height: 16),
        _buildWarningCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB300).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFFB300),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Not medical advice',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'If poor sleep persists for more than 2 weeks, consider speaking with a healthcare provider.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
