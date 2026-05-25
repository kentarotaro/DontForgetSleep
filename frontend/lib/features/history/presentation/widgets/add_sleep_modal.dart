import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/sleep_entry.dart';

Future<SleepEntry?> showAddSleepDialog(
  BuildContext context, {
  required DateTime date,
  required bool hasNightSleep,
}) {
  return showDialog<SleepEntry>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => AddSleepDialog(
      date: date,
      hasNightSleep: hasNightSleep,
    ),
  );
}

Future<SleepEntry?> showEditSleepDialog(
  BuildContext context, {
  required SleepEntry entry,
}) {
  return showDialog<SleepEntry>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => AddSleepDialog(
      date: entry.startTime,
      hasNightSleep: entry.isNap,
      initialEntry: entry,
      isEditing: true,
    ),
  );
}

class AddSleepDialog extends StatefulWidget {
  final DateTime date;
  final bool hasNightSleep;
  final SleepEntry? initialEntry;
  final bool isEditing;

  const AddSleepDialog({
    super.key,
    required this.date,
    required this.hasNightSleep,
    this.initialEntry,
    this.isEditing = false,
  });

  @override
  State<AddSleepDialog> createState() => _AddSleepDialogState();
}

class _AddSleepDialogState extends State<AddSleepDialog> {
  late SleepType _type;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _type = entry.type;
      _startDate = entry.startTime;
      _startTime = TimeOfDay(hour: entry.startTime.hour, minute: entry.startTime.minute);
      _endDate = entry.endTime;
      _endTime = TimeOfDay(hour: entry.endTime.hour, minute: entry.endTime.minute);
    } else {
      _type = widget.hasNightSleep ? SleepType.nap : SleepType.nightSleep;
      _initTimesForType();
    }
  }

  void _initTimesForType() {
    if (_type == SleepType.nightSleep) {
      _startDate = widget.date.subtract(const Duration(days: 1));
      _startTime = const TimeOfDay(hour: 22, minute: 0);
      _endDate = widget.date;
      _endTime = const TimeOfDay(hour: 6, minute: 0);
    } else {
      _startDate = widget.date;
      _startTime = const TimeOfDay(hour: 11, minute: 0);
      _endDate = widget.date;
      _endTime = const TimeOfDay(hour: 12, minute: 0);
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1C24),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF13111A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1C24),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time')),
      );
      return;
    }

    final entry = SleepEntry(
      id: widget.initialEntry?.id ?? '',
      startTime: start,
      endTime: end,
      type: _type,
      quality: widget.initialEntry?.quality ?? 3,
      notes: widget.initialEntry?.notes,
    );
    Navigator.of(context).pop(entry);
  }

  Widget _buildPickerButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Edit Sleep Log'
        : (_type == SleepType.nightSleep ? 'Sleep Log' : 'Naps');
    final subtitle = _type == SleepType.nightSleep
        ? (widget.isEditing ? 'Adjust the recorded sleep session' : 'Total time spent sleeping last night')
        : (widget.isEditing ? 'Adjust the recorded nap session' : 'Total time spent napping today');

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
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!widget.hasNightSleep) ...[
              Container(
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_type != SleepType.nightSleep) {
                            setState(() {
                              _type = SleepType.nightSleep;
                              _initTimesForType();
                            });
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == SleepType.nightSleep
                                ? const Color(0xFF8B5CF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Night Sleep',
                            style: TextStyle(
                              color: _type == SleepType.nightSleep
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: _type == SleepType.nightSleep
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_type != SleepType.nap) {
                            setState(() {
                              _type = SleepType.nap;
                              _initTimesForType();
                            });
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == SleepType.nap
                                ? const Color(0xFF8B5CF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nap',
                            style: TextStyle(
                              color: _type == SleepType.nap
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: _type == SleepType.nap
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                const SizedBox(
                  width: 55,
                  child: Text(
                    'Starts',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildPickerButton(
                    text: DateFormat('d MMM yyyy').format(_startDate),
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildPickerButton(
                    text: _startTime.format(context),
                    onTap: () => _selectTime(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 55,
                  child: Text(
                    'Ends',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildPickerButton(
                    text: DateFormat('d MMM yyyy').format(_endDate),
                    onTap: () => _selectDate(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildPickerButton(
                    text: _endTime.format(context),
                    onTap: () => _selectTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
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
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
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
  }
}
