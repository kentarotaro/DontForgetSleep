import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
// import 'package:dont_forget_sleep/widgets/primary_button.dart';
import 'package:dont_forget_sleep/widgets/secondary_button_button.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/step_progress_bar.dart';
import 'package:dont_forget_sleep/views/get_started/widgets/sleep_floor_option_card.dart';
import 'package:dont_forget_sleep/views/get_started/wake_window_screen.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';

class SetSleepFloorScreen extends StatefulWidget {
  const SetSleepFloorScreen({super.key});

  @override
  State<SetSleepFloorScreen> createState() => _SetSleepFloorScreenState();
}

class _SetSleepFloorScreenState extends State<SetSleepFloorScreen> {
  int _selectedHours = 7; // Default to 7h Balanced

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressBar(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 32),
              Text(
                "STEP 1 OF 2",
                style: AppTextStyles.label.copyWith(
                  color: AppColors.purple500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Set your sleep floor",
                style: AppTextStyles.authTitle.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "The minimum hours you need. We'll never schedule anything that cuts into this.",
                style: AppTextStyles.labelSecondary.copyWith(
                  color: AppColors.purple500,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SleepFloorOptionCard(
                      hours: "6h",
                      label: "Survival",
                      isSelected: _selectedHours == 6,
                      onTap: () => setState(() => _selectedHours = 6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SleepFloorOptionCard(
                      hours: "7h",
                      label: "Balanced",
                      isSelected: _selectedHours == 7,
                      onTap: () => setState(() => _selectedHours = 7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SleepFloorOptionCard(
                      hours: "8h",
                      label: "Optimal",
                      isSelected: _selectedHours == 8,
                      onTap: () => setState(() => _selectedHours = 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Recommendation Box
              if (_selectedHours == 7) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.purple950,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check, color:  Color(0xff7FABFF), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            "Recommended for most students",
                            style: AppTextStyles.label.copyWith(
                              color: const Color(0xff7FABFF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Good balance of productivity and rest",
                        style: AppTextStyles.labelSecondary.copyWith(
                          fontSize: 12,
                          color: const Color(0xff8561B5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SecondaryButton(
                text: "Continue",
                onPressed: () {
                  sleepPreferencesService.setTargetSleepFloorHours(_selectedHours);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WakeWindowScreen(sleepFloorHours: _selectedHours),
                    ),
                  );
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
