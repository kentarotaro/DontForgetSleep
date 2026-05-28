import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/services/calendar_sync_service.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

import 'schedule_planner_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _started = false;
  bool _isConnectingCalendar = false;
  final CalendarSyncService _calendarSyncService = CalendarSyncService();

  @override
  void initState() {
    super.initState();
    _started = sleepPreferencesService.hasCompletedSchedule;
  }

  @override
  void dispose() {
    _calendarSyncService.dispose();
    super.dispose();
  }

  Future<void> _connectCalendar() async {
    setState(() => _isConnectingCalendar = true);
    final result = await _calendarSyncService.connectCalendar();
    if (!mounted) return;
    setState(() => _isConnectingCalendar = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarConnected = sleepPreferencesService.calendarConnected;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _started
              ? const SchedulePlannerPage()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StepProgressBar(
                              currentStep: 0,
                              totalSteps: 3,
                              filledColor: AppColors.purple950,
                              unfilledColor: AppColors.purple950,
                            ),
                            const SizedBox(height: 72),
                            Transform.rotate(
                              angle: 0.0,
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.purple300,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Set Up Your\nSchedule",
                              style: AppTextStyles.authTitle.copyWith(
                                fontSize: 40,
                                height: 1.2,
                                color: Colors.white,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "A clear schedule for you to follow to secure a high quality sleep!",
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.purple500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.purple950,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HOW IT WORKS",
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.purple500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Tell us your schedule, goals and plan. We’ll build a clear schedule that guides you throughout your days and helps maintain your sleep quality.",
                                    style: AppTextStyles.labelSecondary.copyWith(
                                      color: AppColors.purple100,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.purple950,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.purple900,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        color: calendarConnected
                                            ? Colors.teal
                                            : AppColors.purple400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Google Calendar',
                                        style: AppTextStyles.itemTitle,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    calendarConnected
                                        ? 'Connected. Calendar events will be merged into your schedule when available.'
                                        : 'Connect your calendar for a more accurate AI schedule. If your account is not allowed yet, you can still continue without it.',
                                    style: AppTextStyles.itemMeta,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: currentUser == null ||
                                              _isConnectingCalendar
                                          ? null
                                          : _connectCalendar,
                                      icon: _isConnectingCalendar
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              calendarConnected
                                                  ? Icons.sync
                                                  : Icons.link,
                                              color: Colors.white,
                                            ),
                                      label: Text(
                                        _isConnectingCalendar
                                            ? 'Connecting...'
                                            : (calendarConnected
                                                  ? 'Resync Calendar'
                                                  : 'Connect Calendar'),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.purple500,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SecondaryButton(
                              text: 'Get Started',
                              onPressed: () {
                                setState(() => _started = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
