import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
class SettingsSignOutButton extends StatelessWidget {
  const SettingsSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF471B2C)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1E0C1F),
        ),
        onPressed: () {},
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.red300,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}