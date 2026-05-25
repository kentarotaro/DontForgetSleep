import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_card.dart';

class SettingsProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String initials;

  const SettingsProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF73A8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: AppColors.neutral_400, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}