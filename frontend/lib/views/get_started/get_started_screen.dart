import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';
import 'package:dont_forget_sleep/views/get_started/set_sleep_floor_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressBar(currentStep: 0, totalSteps: 3),
              const SizedBox(height: 120),
              Transform.rotate(
                angle: -0.5,
                child: const Icon(
                  Icons.nightlight_round,
                  color: AppColors.purple300,
                  size: 32,
                ),
              ),
              // const Icon(
              //   Icons.nightlight_round,
              //   color: AppColors.purple300,
              //   size: 32,
              // ),
              const SizedBox(height: 16),
              Text(
                "Don't Forget\nSleep",
                style: AppTextStyles.authTitle.copyWith(
                  fontSize: 40,
                  height: 1.2,
                  color: Colors.white,
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Sleep-first scheduling that protects your rest, even when life gets chaotic",
                style: AppTextStyles.label.copyWith(
                  color: AppColors.purple500,
                  fontSize: 16,
                  // height: 1.5,
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
                      "Tell us your schedule. We'll build a plan that guarantees your minimum sleep and help you recover when you miss it",
                      style: AppTextStyles.labelSecondary.copyWith(
                        color: AppColors.purple100,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 32),
              const Spacer(),
              SecondaryButton(
                text: "Get Started",

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetSleepFloorScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
