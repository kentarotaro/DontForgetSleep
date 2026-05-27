import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/time_picker_card.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/navbar.dart';

class WakeWindowScreen extends StatefulWidget {
  final int sleepFloorHours;

  const WakeWindowScreen({super.key, required this.sleepFloorHours});

  @override
  State<WakeWindowScreen> createState() => _WakeWindowScreenState();
}

class _WakeWindowScreenState extends State<WakeWindowScreen> {
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  bool _isSaving = false;

  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay initialTime = isWakeUp ? _wakeUpTime : _bedTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple400,
              onPrimary: AppColors.scaffoldBg,
              surface: AppColors.purple950,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _bedTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateSleepDuration() {
    int bedHour = _bedTime.hour;
    int wakeHour = _wakeUpTime.hour;
    int bedMinute = _bedTime.minute;
    int wakeMinute = _wakeUpTime.minute;

    if (wakeHour < bedHour || (wakeHour == bedHour && wakeMinute < bedMinute)) {
      wakeHour += 24;
    }

    int totalMinutes =
        (wakeHour * 60 + wakeMinute) - (bedHour * 60 + bedMinute);
    return (totalMinutes / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    final sleepDuration = _calculateSleepDuration();
    final bool isAboveFloor = sleepDuration >= widget.sleepFloorHours;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressBar(currentStep: 2, totalSteps: 3),
              const SizedBox(height: 32),
              Text(
                "STEP 2 OF 2",
                style: AppTextStyles.label.copyWith(
                  color: AppColors.purple500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Set your wake window",
                style: AppTextStyles.authTitle.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "What are your ideal wake-up and bedtime goals?",
                style: AppTextStyles.labelSecondary.copyWith(
                  color: AppColors.purple500,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TimePickerCard(
                icon: Icons.wb_sunny,
                iconColor: Colors.amber,
                title: "Wake up",
                timeString: _formatTime(_wakeUpTime),
                onTap: () => _selectTime(context, true),
              ),
              const SizedBox(height: 12),
              TimePickerCard(
                icon: Icons.nightlight_round,
                iconColor: Colors.amber,
                title: "Bedtime",
                timeString: _formatTime(_bedTime),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 24),
              // Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.purple950,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: -0.5,
                          child: const Icon(
                            Icons.nightlight_round,
                            color: AppColors.purple300,
                            size: 16,
                          ),
                        ),
                        // const Icon(Icons.nightlight_round, color: AppColors.purple300, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Sleep window: ${_formatTime(_bedTime)} → ${_formatTime(_wakeUpTime)} (${sleepDuration}h)",
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAboveFloor
                          ? "Above your ${widget.sleepFloorHours}h floor, great start!"
                          : "Below your ${widget.sleepFloorHours}h floor, you might want to adjust this.",
                      style: AppTextStyles.labelSecondary.copyWith(
                        fontSize: 12,
                        color: isAboveFloor
                            ? AppColors.purple350
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SecondaryButton(
                text: "Continue",
                isBusy: _isSaving,
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _isSaving = true;
                        });

                        final navigator = Navigator.of(context);
                        final user = FirebaseAuth.instance.currentUser;

                        sleepPreferencesService.setTargetSleepFloorHours(
                          widget.sleepFloorHours,
                        );
                        if (user != null) {
                          sleepPreferencesService.updateWakeTime(
                            user.uid,
                            _formatTime(_wakeUpTime),
                          );
                          sleepPreferencesService.updateBedtime(
                            user.uid,
                            _formatTime(_bedTime),
                          );
                        }
                        sleepPreferencesService.completeOnboarding();
                        sleepPreferencesService.completeSettings();

                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                          (route) => false,
                        );

                        if (user != null) {
                          unawaited(
                            FirebaseFirestore.instance
                                .collection('userProfiles')
                                .doc(user.uid)
                                .set({
                                  'sleepFloorHours': widget.sleepFloorHours,
                                  'targetSleepHours': widget.sleepFloorHours,
                                  'preferredWakeTime': _formatTime(_wakeUpTime),
                                  'preferredBedtime': _formatTime(_bedTime),
                                  'settingsCompleted': true,
                                }, SetOptions(merge: true))
                                .whenComplete(() {
                                  if (mounted) {
                                    setState(() {
                                      _isSaving = false;
                                    });
                                  }
                                }),
                          );
                        } else if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Back",
                    style: AppTextStyles.labelSecondary.copyWith(
                      color: const Color(0xff8561B5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
