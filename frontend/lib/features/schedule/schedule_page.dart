import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';

import 'schedule_planner_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _started ? const SchedulePlannerPage() : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepProgressBar(
                  currentStep: 0,
                  totalSteps: 3,
                  filledColor: AppColors.purple950,
                  unfilledColor: AppColors.purple950,
                ),
                const SizedBox(height: 120),
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
                const Spacer(),
                SecondaryButton(
                  text: 'Get Started',
                  onPressed: () {
                    setState(() => _started = true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}