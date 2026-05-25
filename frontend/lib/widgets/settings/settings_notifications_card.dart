import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_header.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_switch_row.dart';

class SettingsNotificationsCard extends StatelessWidget {
  final bool bedtimeReminder;
  final bool caffeineReminder;
  final bool checkinReminder;
  final bool rescueReminder;
  final ValueChanged<bool> onBedtimeReminderChanged;
  final ValueChanged<bool> onCaffeineReminderChanged;
  final ValueChanged<bool> onCheckinReminderChanged;
  final ValueChanged<bool> onRescueReminderChanged;

  const SettingsNotificationsCard({
    super.key,
    required this.bedtimeReminder,
    required this.caffeineReminder,
    required this.checkinReminder,
    required this.rescueReminder,
    required this.onBedtimeReminderChanged,
    required this.onCaffeineReminderChanged,
    required this.onCheckinReminderChanged,
    required this.onRescueReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'NOTIFICATION'),
        SettingsSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: Border.all(color: AppColors.purple900, width: 1),
          child: Column(
            children: [
              SettingsSwitchRow(
                label: 'Bedtime Reminder',
                value: bedtimeReminder,
                onChanged: onBedtimeReminderChanged,
                showDivider: true,
              ),
              SettingsSwitchRow(
                label: 'Caffeine Reminder',
                value: caffeineReminder,
                onChanged: onCaffeineReminderChanged,
                showDivider: true,
              ),
              SettingsSwitchRow(
                label: 'Checkin Reminder',
                value: checkinReminder,
                onChanged: onCheckinReminderChanged,
                showDivider: true,
              ),
              SettingsSwitchRow(
                label: 'Rescue Reminder',
                value: rescueReminder,
                onChanged: onRescueReminderChanged,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}