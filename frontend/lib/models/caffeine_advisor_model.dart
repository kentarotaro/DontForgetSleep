class NapRecommendation {
  final String title;
  final String duration;
  final String description;
  final bool isRecommended;

  NapRecommendation({
    required this.title,
    required this.duration,
    required this.description,
    this.isRecommended = false,
  });
}

class CaffeineAdvisorData {
  final String bestTime;
  final String latestCutoff;
  final String statusMessage;
  final bool isSafeWindow;
  final List<NapRecommendation> naps;
  final String bestNapWindow;
  final String bestNapSubtitle;
  final String adviceText;
  final List<String> tips;
  final bool shouldAvoidCaffeine;

  CaffeineAdvisorData({
    required this.bestTime,
    required this.latestCutoff,
    required this.statusMessage,
    required this.isSafeWindow,
    required this.naps,
    required this.bestNapWindow,
    required this.bestNapSubtitle,
    this.adviceText = '',
    this.tips = const [],
    this.shouldAvoidCaffeine = false,
  });
}
