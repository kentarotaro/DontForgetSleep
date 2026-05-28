class DailyAiSnapshot {
  final String sessionId;
  final String date;
  final Map<String, dynamic> raw;

  const DailyAiSnapshot({
    required this.sessionId,
    required this.date,
    required this.raw,
  });
}
