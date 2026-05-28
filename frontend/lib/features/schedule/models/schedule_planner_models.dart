class Commitment {
  final String name;
  final String day;
  final String category;
  final double start;
  final double end;

  Commitment({
    required this.name,
    required this.day,
    required this.category,
    required this.start,
    required this.end,
  });
}

class Goal {
  final String name;
  final int duration;
  final String frequency;

  Goal({
    required this.name,
    required this.duration,
    required this.frequency,
  });
}

class ScheduleBlock {
  final String name;
  final double start;
  final double end;
  final String type;
  final int goalIndex;

  ScheduleBlock({
    required this.name,
    required this.start,
    required this.end,
    required this.type,
    this.goalIndex = -1,
  });
}
