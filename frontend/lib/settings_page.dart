import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dont_forget_sleep/core/auth_service.dart';
import 'package:dont_forget_sleep/onboarding_page.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';
import 'package:dont_forget_sleep/services/sleep_preferences_service.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_notifications_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_profile_card.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_sign_out_button.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_sleep_preferences_section.dart';
import 'package:dont_forget_sleep/widgets/settings/settings_section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();

  int _minSleepIndex = 1;
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bed = const TimeOfDay(hour: 23, minute: 0);

  bool _bedtimeReminder = true;
  bool _caffeineReminder = true;
  bool _checkinReminder = true;
  bool _rescueReminder = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    sleepPreferencesService.addListener(_onPreferencesChanged);
    _loadFromPreferences();
  }

  @override
  void dispose() {
    sleepPreferencesService.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        _loadFromPreferences();
      });
    }
  }

  void _loadFromPreferences() {
    final hours = sleepPreferencesService.targetSleepFloorHours;
    if (hours == 6) {
      _minSleepIndex = 0;
    } else if (hours == 8) {
      _minSleepIndex = 2;
    } else {
      _minSleepIndex = 1; // 7h
    }

    _wake = _parseTimeString(sleepPreferencesService.preferredWakeTime);
    _bed = _parseTimeString(sleepPreferencesService.preferredBedtime);

    _bedtimeReminder = sleepPreferencesService.bedtimeReminder;
    _caffeineReminder = sleepPreferencesService.caffeineReminder;
    _checkinReminder = sleepPreferencesService.checkinReminder;
    _rescueReminder = sleepPreferencesService.rescueReminder;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  String _resolveDisplayName(User? user) {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  String _resolveEmail(User? user) {
    final email = user?.email?.trim() ?? '';
    return email.isNotEmpty ? email : 'No email';
  }

  String _resolveInitials(User? user) {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out right now. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<void> _selectWakeTime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wake,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple500,
              onPrimary: Colors.white,
              surface: AppColors.bgCard,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.scaffoldBg,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _wake) {
      setState(() {
        _wake = picked;
      });
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await sleepPreferencesService.updateWakeTime(uid, timeStr);
    }
  }

  Future<void> _selectBedTime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bed,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple500,
              onPrimary: Colors.white,
              surface: AppColors.bgCard,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.scaffoldBg,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _bed) {
      setState(() {
        _bed = picked;
      });
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await sleepPreferencesService.updateBedtime(uid, timeStr);
    }
  }

  Widget _buildGoogleCalendarSection() {
    final connected = sleepPreferencesService.calendarConnected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: connected ? Colors.teal : AppColors.purple400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google Calendar',
                      style: AppTextStyles.itemTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connected ? Icons.check_circle : Icons.info_outline,
                    color: connected ? Colors.teal : AppColors.purple400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    connected ? 'Connected' : 'Manage from Schedule',
                    style: TextStyle(
                      color: connected ? Colors.teal : AppColors.purple400,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          connected
              ? 'Your calendar events are successfully synchronized and used during schedule generation.'
              : 'Calendar connection now lives in the Schedule tab so it stays close to the planning flow.',
          style: AppTextStyles.itemMeta,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
            SettingsProfileCard(
              name: _resolveDisplayName(currentUser),
              email: _resolveEmail(currentUser),
              initials: _resolveInitials(currentUser),
            ),
            const SizedBox(height: 16),
            SettingsSleepPreferencesSection(
              selectedIndex: _minSleepIndex,
              onSelectedIndexChanged: (index) async {
                setState(() => _minSleepIndex = index);
                final hours = index == 0 ? 6 : (index == 2 ? 8 : 7);
                final uid = currentUser?.uid;
                if (uid != null) {
                  await sleepPreferencesService.updateSleepFloor(uid, hours);
                }
              },
              wakeTimeText: _wake.format(context),
              bedTimeText: _bed.format(context),
              onWakeTimeTap: _selectWakeTime,
              onBedTimeTap: _selectBedTime,
            ),
            const SizedBox(height: 16),
            SettingsSectionCard(
              border: Border.all(color: AppColors.purple900, width: 1),
              child: _buildGoogleCalendarSection(),
            ),
            const SizedBox(height: 16),
            SettingsNotificationsCard(
              bedtimeReminder: _bedtimeReminder,
              caffeineReminder: _caffeineReminder,
              checkinReminder: _checkinReminder,
              rescueReminder: _rescueReminder,
              onBedtimeReminderChanged: (value) async {
                final uid = currentUser?.uid;
                if (uid != null) {
                  setState(() => _bedtimeReminder = value);
                  await sleepPreferencesService.updateNotificationSettings(uid: uid, bedtime: value);
                }
              },
              onCaffeineReminderChanged: (value) async {
                final uid = currentUser?.uid;
                if (uid != null) {
                  setState(() => _caffeineReminder = value);
                  await sleepPreferencesService.updateNotificationSettings(uid: uid, caffeine: value);
                }
              },
              onCheckinReminderChanged: (value) async {
                final uid = currentUser?.uid;
                if (uid != null) {
                  setState(() => _checkinReminder = value);
                  await sleepPreferencesService.updateNotificationSettings(uid: uid, checkin: value);
                }
              },
              onRescueReminderChanged: (value) async {
                final uid = currentUser?.uid;
                if (uid != null) {
                  setState(() => _rescueReminder = value);
                  await sleepPreferencesService.updateNotificationSettings(uid: uid, rescue: value);
                }
              },
            ),
            const SizedBox(height: 24),
            SettingsSignOutButton(
              onPressed: _handleSignOut,
              isBusy: _isSigningOut,
            ),
          ],
        ),
      ),
    );
  }
}
