import 'package:flutter/material.dart';
import '../models/rescue_plan_model.dart';
import '../repositories/rescue_repository.dart';
import '../widgets/rescue_summary_card.dart';
import '../widgets/recovery_stat_card.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/glowing_status_widget.dart';
import '../widgets/rescue_toggle_tab.dart';

class RescueModePage extends StatefulWidget {
  final double sleepHours;

  const RescueModePage({Key? key, required this.sleepHours}) : super(key: key);

  @override
  State<RescueModePage> createState() => _RescueModePageState();
}

class _RescueModePageState extends State<RescueModePage> {
  final RescueRepository _repository = RescueRepository();
  RescuePlan? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final plan = await _repository.getRescuePlan(widget.sleepHours);
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load rescue plan')),
        );
      }
    }
  }

  void _toggleChecklistItem(String id) {
    if (_plan == null) return;
    
    setState(() {
      final updatedChecklist = _plan!.checklist.map((item) {
        if (item.id == id) {
          return item.copyWith(isCompleted: !item.isCompleted);
        }
        return item;
      }).toList();

      _plan = RescuePlan(
        type: _plan!.type,
        hoursSlept: _plan!.hoursSlept,
        title: _plan!.title,
        subtitle: _plan!.subtitle,
        checklist: updatedChecklist,
        napWindow: _plan!.napWindow,
        caffeineStop: _plan!.caffeineStop,
        newBedtime: _plan!.newBedtime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E), // Dark purple/navy background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9151F5)))
            : _plan == null
                ? const Center(child: Text('No data available', style: TextStyle(color: Colors.white)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_plan!.type == RescueType.normal) {
      return _buildNormalContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RescueToggleTab(type: _plan!.type),
          const SizedBox(height: 24),
          _buildRecoveryPlan(),
        ],
      ),
    );
  }

  Widget _buildNormalContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF131428), Color(0xFF1A1630)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2D2550), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E676).withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: Color(0xFF00E676),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _plan!.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _plan!.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1224),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Sleep rhythm is stable today',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  'What to keep doing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Keep a steady wake-up time',
                  subtitle: 'Wake up around the same time tomorrow.',
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.local_cafe_outlined,
                  title: 'Caffeine is fine in moderation',
                  subtitle: 'Stay mindful of late afternoon coffee.',
                ),
                const SizedBox(height: 12),
                _buildNormalTip(
                  icon: Icons.bedtime_outlined,
                  title: 'Protect your bedtime window',
                  subtitle: 'A consistent bedtime keeps your rhythm balanced.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlowingStatusWidget(title: _plan!.title, subtitle: _plan!.subtitle),
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

  Widget _buildRecoveryPlan() {
    final completedCount = _plan!.checklist.where((i) => i.isCompleted).length;
    final totalCount = _plan!.checklist.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RescueSummaryCard(plan: _plan!),
        const SizedBox(height: 16),

        if (_plan!.type == RescueType.underslept)
          Row(
            children: [
              Expanded(
                child: RecoveryStatCard(
                  time: _plan!.napWindow ?? '-',
                  label: 'Nap window',
                  timeColor: const Color(0xFF00E676), // Cyan-green
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RecoveryStatCard(
                  time: _plan!.caffeineStop ?? '-',
                  label: 'Caffeine stop',
                  timeColor: const Color(0xFFFF6B6B), // Red-coral
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RecoveryStatCard(
                  time: _plan!.newBedtime ?? '-',
                  label: 'New bedtime',
                  timeColor: const Color(0xFFB388FF), // Purple
                ),
              ),
            ],
          ),

        if (_plan!.type == RescueType.underslept)
          const SizedBox(height: 32),
        if (_plan!.type == RescueType.overslept)
          const SizedBox(height: 24),

        Text(
          'RECOVERY CHECKLIST ($completedCount/$totalCount DONE)',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        ..._plan!.checklist.map((item) => ChecklistTile(
              item: item,
              onToggle: () => _toggleChecklistItem(item.id),
            )),

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
        color: const Color(0xFF2A1C16), // Dark orange/brown tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 18),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
