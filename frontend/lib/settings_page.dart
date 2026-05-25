import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_notifications_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_profile_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_sign_out_button.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_sleep_preferences_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _minSleepIndex = 1;
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bed = const TimeOfDay(hour: 23, minute: 0);

  bool _bedtimeReminder = true;
  bool _caffeineReminder = true;
  bool _checkinReminder = true;
  bool _rescueReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsProfileCard(
              name: 'John Wick',
              email: 'johnwick@continental.com',
              initials: 'J',
            ),
            const SizedBox(height: 16),
            SettingsSleepPreferencesSection(
              selectedIndex: _minSleepIndex,
              onSelectedIndexChanged: (index) => setState(() => _minSleepIndex = index),
              wakeTimeText: _wake.format(context),
              bedTimeText: _bed.format(context),
            ),
            const SizedBox(height: 16),
            SettingsNotificationsCard(
              bedtimeReminder: _bedtimeReminder,
              caffeineReminder: _caffeineReminder,
              checkinReminder: _checkinReminder,
              rescueReminder: _rescueReminder,
              onBedtimeReminderChanged: (value) => setState(() => _bedtimeReminder = value),
              onCaffeineReminderChanged: (value) => setState(() => _caffeineReminder = value),
              onCheckinReminderChanged: (value) => setState(() => _checkinReminder = value),
              onRescueReminderChanged: (value) => setState(() => _rescueReminder = value),
            ),
            const SizedBox(height: 24),
            const SettingsSignOutButton(),
          ],
        ),
      ),
    );
  }
}