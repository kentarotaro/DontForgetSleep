enum RescueType {
  underslept,
  overslept,
  normal,
}

class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RescuePlan {
  final RescueType type;
  final double hoursSlept;
  final String title;
  final String subtitle;
  final List<ChecklistItem> checklist;
  
  // Specific to underslept
  final String? napWindow;
  final String? caffeineStop;
  final String? newBedtime;

  RescuePlan({
    required this.type,
    required this.hoursSlept,
    required this.title,
    required this.subtitle,
    required this.checklist,
    this.napWindow,
    this.caffeineStop,
    this.newBedtime,
  });
}
