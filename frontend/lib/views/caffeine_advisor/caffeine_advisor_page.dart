import 'package:dont_forget_sleep/features/rescue_mode/repositories/daily_ai_repository.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/caffeine_advisor_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/caffeine_advisor/info_card.dart';
import '../../widgets/caffeine_advisor/nap_card.dart';

class CaffeineAdvisorPage extends StatefulWidget {
  const CaffeineAdvisorPage({super.key});

  @override
  State<CaffeineAdvisorPage> createState() => _CaffeineAdvisorPageState();
}

class _CaffeineAdvisorPageState extends State<CaffeineAdvisorPage>
    with SingleTickerProviderStateMixin {
  CaffeineAdvisorData? _data;
  bool _isLoading = true;
  // ignore: unused_field
  bool _usingAiSnapshot = false;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final advisorContext = await _loadAdvisorContext();
      final snapshot = await dailyAiRepository.getTodaySnapshot();
      final data = snapshot != null
          ? _buildFromAi(snapshot.raw, advisorContext)
          : _buildFallbackData(advisorContext);
      if (mounted) {
        setState(() {
          _data = data;
          _usingAiSnapshot = snapshot != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = _buildFallbackData(const _AdvisorContext());
          _usingAiSnapshot = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falling back to local guidance')),
        );
      }
    }
  }

  Future<_AdvisorContext> _loadAdvisorContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const _AdvisorContext();

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final checkinId = 'checkin_${uid}_$todayStr';

    int? caffeineMg;
    int? energyLevel;
    double? sleepHours;

    try {
      final checkinDoc = await FirebaseFirestore.instance
          .collection('dailyCheckins')
          .doc(checkinId)
          .get();
      final data = checkinDoc.data();
      caffeineMg = (data?['caffeineIntakeMg'] as num?)?.round();
      energyLevel = (data?['energyLevel'] as num?)?.round();
    } catch (_) {}

    try {
      final sleepSnapshot = await FirebaseFirestore.instance
          .collection('sleepLogs')
          .where('userId', isEqualTo: uid)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();
      if (sleepSnapshot.docs.isNotEmpty) {
        final sleepData = sleepSnapshot.docs.first.data();
        final durationMinutes = sleepData['durationMinutes'] as num?;
        if (durationMinutes != null) {
          sleepHours = durationMinutes / 60.0;
        }
      }
    } catch (_) {}

    return _AdvisorContext(
      caffeineIntakeMg: caffeineMg,
      energyLevel: energyLevel,
      sleepHours: sleepHours,
    );
  }

  CaffeineAdvisorData _buildFromAi(Map<String, dynamic> raw, _AdvisorContext context) {
    final aiPayload = _unwrapAiPayload(raw);
    final sleepWindowSuggestion = _mapValue(aiPayload['sleepWindowSuggestion']);

    final recommendedBedtime = _stringValue(
      sleepWindowSuggestion?['recommendedBedtime'],
      fallback: sleepPreferencesService.preferredBedtime,
    );
    final recommendedWakeTime = _stringValue(
      sleepWindowSuggestion?['recommendedWakeTime'],
      fallback: sleepPreferencesService.preferredWakeTime,
    );

    String? cutoffTime;
    String adviceText = 'AI guidance for today based on your sleep context.';
    List<String> caffeineTips = [];
    bool shouldAvoidCaffeine = false;

    final rawCaffeineAdvice = aiPayload['caffeineAdvice'];
    if (rawCaffeineAdvice is Map) {
      cutoffTime = rawCaffeineAdvice['caffeineCutoffTime']?.toString();
      shouldAvoidCaffeine = rawCaffeineAdvice['shouldAvoidCaffeine'] == true;
      caffeineTips = _toStringList(rawCaffeineAdvice['tips']);
      if (shouldAvoidCaffeine) {
        adviceText = cutoffTime != null && cutoffTime.isNotEmpty
            ? 'Avoid caffeine today until $cutoffTime.'
            : 'Avoid caffeine today.';
      }
    } else if (rawCaffeineAdvice != null && rawCaffeineAdvice.toString().isNotEmpty) {
      final adviceStr = rawCaffeineAdvice.toString();
      cutoffTime = _extractTime(adviceStr);
      adviceText = adviceStr;
      caffeineTips = adviceStr
          .split(RegExp(r'\.|\n'))
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final caffeineCutoffTime = cutoffTime ?? _shiftTime(recommendedBedtime, -8);
    
    final bestTime = _shiftTime(recommendedWakeTime, 1, 30);
    final napWindow = _extractNapWindow(aiPayload) ?? _buildNapWindow(recommendedWakeTime);
    final safe = _isNowBefore(caffeineCutoffTime);

    // Use local, hard-coded nap advisor logic based on user's context
    final naps = _buildDynamicNaps(
      context,
      caffeineTips: caffeineTips,
      shouldAvoidCaffeine: false,
      reasoningTitle: '',
      reasoningDetails: '',
      cutoffTime: caffeineCutoffTime,
    );

    return CaffeineAdvisorData(
      bestTime: bestTime,
      latestCutoff: caffeineCutoffTime,
      // Always use dynamic (local) status messaging when backend AI isn't used for naps
      statusMessage: _buildDynamicStatusMessage(
        safe: safe,
        latestCutoff: caffeineCutoffTime,
        context: context,
      ),
      isSafeWindow: safe,
      bestNapWindow: napWindow,
      bestNapSubtitle: 'Calculated from your preferred wake and bedtime',
      adviceText: adviceText,
      naps: naps,
      tips: caffeineTips,
      shouldAvoidCaffeine: shouldAvoidCaffeine,
    );
  }

  CaffeineAdvisorData _buildFallbackData(_AdvisorContext context) {
    final wakeTime = sleepPreferencesService.preferredWakeTime;
    final bedtime = sleepPreferencesService.preferredBedtime;
    final bestTime = _shiftTime(wakeTime, 1, 30);
    final latestCutoff = _shiftTime(bedtime, -8);
    final safe = _isNowBefore(latestCutoff);

    final naps = _buildDynamicNaps(
      context,
      caffeineTips: const [],
      shouldAvoidCaffeine: false,
      reasoningTitle: '',
      reasoningDetails: '',
      cutoffTime: latestCutoff,
    );

    return CaffeineAdvisorData(
      bestTime: bestTime,
      latestCutoff: latestCutoff,
      statusMessage: _buildDynamicStatusMessage(
        safe: safe,
        latestCutoff: latestCutoff,
        context: context,
      ),
      isSafeWindow: safe,
      bestNapWindow: _buildNapWindow(wakeTime),
      bestNapSubtitle: 'Calculated from your preferred wake and bedtime',
      adviceText: 'AI caffeine advice is not available yet.',
      naps: naps,
      tips: const [],
      shouldAvoidCaffeine: false,
    );
  }

  List<NapRecommendation> _buildDynamicNaps(
    _AdvisorContext context, {
    required List<String> caffeineTips,
    required bool shouldAvoidCaffeine,
    required String reasoningTitle,
    required String reasoningDetails,
    required String cutoffTime,
  }) {
    final targetFloor = sleepPreferencesService.targetSleepFloorHours.toDouble();
    final sleepHrs = context.sleepHours;

    // Determine sleep status
    final bool isUnderslept = sleepHrs != null && sleepHrs < targetFloor;
    final bool isOverslept = sleepHrs != null && sleepHrs > 9.0;

    if (isOverslept) {
      return [
        NapRecommendation(
          title: 'Avoid Napping',
          duration: 'All day',
          description: 'Avoid napping today to preserve your sleep pressure and make it easier to fall asleep tonight.',
          isRecommended: false,
        ),
        NapRecommendation(
          title: 'Seek Sunlight',
          duration: 'Morning/Afternoon',
          description: 'Get bright light exposure early in the day to stop melatonin production and reset your clock.',
        ),
      ];
    } else if (isUnderslept) {
      return [
        NapRecommendation(
          title: 'Power Nap',
          duration: '15-20 min',
          description: 'A brief nap is highly recommended to restore alertness and cognitive function without causing sleep inertia.',
          isRecommended: true,
        ),
        NapRecommendation(
          title: 'Sleep Recovery',
          duration: 'Tonight',
          description: 'Prioritize an earlier bedtime tonight to catch up on your accumulated sleep debt.',
        ),
      ];
    } else {
      return [
        NapRecommendation(
          title: 'Power Nap',
          duration: '10-20 min',
          description: 'Optional quick recharge that boosts afternoon alertness without disrupting your night sleep.',
          isRecommended: true,
        ),
        NapRecommendation(
          title: 'Maintain Routine',
          duration: 'Tonight',
          description: 'Your sleep was balanced. Try to target your preferred bedtime to maintain circadian rhythm.',
        ),
      ];
    }
  }

  

  String _buildDynamicStatusMessage({
    required bool safe,
    required String latestCutoff,
    required _AdvisorContext context,
  }) {
    final prefix = _currentTimeLabel();

    if (safe) {
      return '$prefix you are in today\'s safer caffeine window.';
    }

    return '$prefix you are past today\'s cutoff ($latestCutoff).';
  }

  String _buildNapWindow(String wakeTime) {
    final start = _shiftTime(wakeTime, 6, 0);
    final end = _shiftTime(wakeTime, 6, 30);
    return '$start - $end';
  }

  String? _extractNapWindow(Map<String, dynamic> raw) {
    final checklistItems = raw['checklistItems'];
    if (checklistItems is List) {
      for (final item in checklistItems) {
        if (item is Map) {
          final action = _stringValue(item['action']);
          final matches = RegExp(r'\b\d{2}:\d{2}\b').allMatches(action).toList();
          if (matches.length >= 2) {
            return '${matches[0].group(0)} - ${matches[1].group(0)}';
          }
          final oneTime = _extractTime(action);
          if (oneTime != null && action.toLowerCase().contains('nap')) {
            return '$oneTime - ${_shiftTime(oneTime, 0, 20)}';
          }
        }
      }
    }

    final wakeTime = _stringValue(
      (raw['sleepWindowSuggestion'] as Map?)?['recommendedWakeTime'],
    );
    if (wakeTime.isNotEmpty) {
      return '${_shiftTime(wakeTime, 6, 0)} - ${_shiftTime(wakeTime, 6, 30)}';
    }
    return null;
  }

  String _currentTimeLabel() {
    final now = TimeOfDay.now();
    return 'It\'s ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')},';
  }

  Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const [];
    }

    return text
        .split(RegExp(r'\r?\n|;'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _unwrapAiPayload(Map<String, dynamic> raw) {
    final nestedData = _mapValue(raw['data']);
    return nestedData ?? raw;
  }

  



  String _shiftTime(String timeStr, int hourOffset, [int minuteOffset = 0]) {
    try {
      final parts = timeStr.split(':');
      var totalMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      totalMinutes += (hourOffset * 60) + minuteOffset;
      totalMinutes %= 24 * 60;
      if (totalMinutes < 0) {
        totalMinutes += 24 * 60;
      }
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  bool _isNowBefore(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final cutoffMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes <= cutoffMinutes;
    } catch (_) {
      return true;
    }
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _extractTime(String text) {
    final match = RegExp(r'\b\d{2}:\d{2}\b').firstMatch(text);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Caffeine Advisor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton()
            : _data == null
                ? const Center(
                    child: Text('No data available', style: TextStyle(color: Colors.white)),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildSkeletonCard(220, _shimmerAnimation.value),
              const SizedBox(height: 24),
              _buildSkeletonCard(280, _shimmerAnimation.value),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard(double height, double opacity) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity * 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          _buildCaffeineWindowCard(),
          const SizedBox(height: 24),
          // const Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     'AI Caffeine Advice',
          //     style: TextStyle(
          //       color: AppColors.purple300,
          //       fontSize: 12,
          //       fontWeight: FontWeight.w600,
          //       letterSpacing: 0.4,
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 10),
          // _buildCaffeineAdviceCard(),
          const SizedBox(height: 24),
          _buildNapAdvisorSection(),
          const SizedBox(height: 12),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     _usingAiSnapshot
          //         ? 'Using today\'s shared AI rescue guidance'
          //         : 'Using local personalized guidance until Rescue Mode generates AI today',
          //     style: const TextStyle(color: AppColors.purple300, fontSize: 12),
          //   ),
          // ),
          // const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCaffeineAdviceCard() {
    final hasAiAdvice = _data != null && (
      _data!.adviceText.isNotEmpty || _data!.tips.isNotEmpty || _data!.shouldAvoidCaffeine
    );
    final renderedTips = _data == null
        ? const <String>[]
        : (_data!.tips.isNotEmpty ? _data!.tips : (_data!.adviceText.isNotEmpty ? [_data!.adviceText] : const <String>[]));

    final accent = hasAiAdvice && _data!.shouldAvoidCaffeine
      ? const Color(0xFFFF5252)
      : const Color(0xFF00D794);
    final title = hasAiAdvice
      ? (_data!.shouldAvoidCaffeine ? 'Avoid caffeine for now' : 'Caffeine advice')
      : 'Caffeine advice pending';
    final subtitle = hasAiAdvice
      ? (_data!.shouldAvoidCaffeine
        ? 'Your current window suggests skipping caffeine until after the cutoff.'
        : 'AI guidance for today based on your sleep context.')
      : 'This card appears when the AI rescue snapshot is available.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1328), Color(0xFF22122D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee_outlined, color: accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF251E31),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_data!.adviceText.isNotEmpty) ...[
                  Text(
                    _data!.adviceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Cutoff: ${_data!.latestCutoff}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tips',
                  style: TextStyle(color: AppColors.purple300, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (renderedTips.isNotEmpty)
                  ...renderedTips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.white70)),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  const Text(
                    'Waiting for AI tips from Rescue Mode snapshot.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaffeineWindowCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff210D1B), Color(0xFF271647)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff4B1E2F), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.coffee_outlined, color: Color(0xFFFFB300), size: 22),
              SizedBox(width: 10),
              Text(
                'Caffeine Window',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Expanded(
              //   child: InfoCard(
              //     title: 'Best time',
              //     value: _data!.bestTime,
              //     subtitle: '90 min after wake',
              //     valueColor: const Color(0xFF00D794),
              //   ),
              // ),
              // const SizedBox(width: 16),
              Expanded(
                child: InfoCard(
                  title: 'Latest cutoff',
                  value: _data!.latestCutoff,
                  subtitle: '8h before bed',
                  valueColor: const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF251E31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _data!.isSafeWindow ? Icons.check : Icons.close,
                  color: _data!.isSafeWindow
                      ? const Color(0xFF00D794)
                      : const Color(0xFFFF5252),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _data!.statusMessage,
                    style: TextStyle(
                      color: _data!.isSafeWindow
                          ? const Color(0xFF00D794)
                          : const Color(0xFFFF5252),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_data!.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tips',
              style: const TextStyle(
                color: AppColors.purple300,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._data!.tips.take(3).map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNapAdvisorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF222B3A), Color(0xFF1E192E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.nightlight_round_sharp, color: Color(0xFF00BFA5), size: 20),
              SizedBox(width: 10),
              Text(
                'Nap Advisor',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: NapCard(
                    title: _data!.naps[0].title,
                    duration: _data!.naps[0].duration,
                    description: _data!.naps[0].description,
                    isRecommended: _data!.naps[0].isRecommended,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NapCard(
                    title: _data!.naps[1].title,
                    duration: _data!.naps[1].duration,
                    description: _data!.naps[1].description,
                    isRecommended: _data!.naps[1].isRecommended,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C0E30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best nap window today',
                  style: TextStyle(
                    color: AppColors.purple300,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _data!.bestNapWindow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _data!.bestNapSubtitle,
                  style: const TextStyle(
                    color: AppColors.purple300,
                    fontSize: 12,
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

class _AdvisorContext {
  final int? caffeineIntakeMg;
  final int? energyLevel;
  final double? sleepHours;

  const _AdvisorContext({
    this.caffeineIntakeMg,
    this.energyLevel,
    this.sleepHours,
  });
}
