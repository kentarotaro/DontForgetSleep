enum SleepType { nightSleep, nap }

class SleepEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final SleepType type;
  final int quality; // 1 to 5
  final String? notes;

  SleepEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.type = SleepType.nightSleep,
    this.quality = 3,
    this.notes,
  });

  SleepEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    SleepType? type,
    int? quality,
    String? notes,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }

  Duration get duration => endTime.difference(startTime);

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  bool get isNap => type == SleepType.nap;

  bool get crossesMidnight {
    if (isNap) return false;
    return startTime.year != endTime.year ||
        startTime.month != endTime.month ||
        startTime.day != endTime.day;
  }
}
