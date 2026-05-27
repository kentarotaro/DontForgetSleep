import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Initialize timezone data
      tz.initializeTimeZones();
      final String timeZoneName = 'Asia/Jakarta';
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // 2. Setup initialization settings for Android and iOS
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification click if needed
        },
      );

      _initialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('Error initializing local notifications: $e');
    }
  }

  // Request permissions explicitly (needed for Android 13+)
  Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error requesting notification permissions: $e');
    }
  }

  // Show an instant local notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dfs_instant_notifications',
      'DFS Immediate Notifications',
      channelDescription: 'Immediate feedback and alerts for DFS',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Schedule a daily recurring notification at a specific time (HH:MM)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required String timeStr, // "HH:MM" e.g. "23:00"
  }) async {
    if (!_initialized) await init();

    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time is in the past today, move to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'dfs_scheduled_reminders',
        'DFS Reminders',
        channelDescription: 'Scheduled reminders for bedtime, caffeine and check-ins',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error scheduling notification ID $id: $e');
    }
  }

  // Schedule a one-time re-engage notification in 48 hours
  Future<void> scheduleReengageReminder() async {
    if (!_initialized) await init();
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 48));
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'dfs_reengage',
        'DFS Re-engagement',
        channelDescription: 'Reminds you to check in after 48h of inactivity',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: 108,
        title: '👋 Keeping insights accurate',
        body: "Haven't seen you in 2 days — check in to keep insights accurate",
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error scheduling re-engage: $e');
    }
  }

  // Schedule Nap window closing notification (15 minutes before nap start)
  Future<void> scheduleNapClosingNotification({
    required DateTime napStartTime,
  }) async {
    if (!_initialized) await init();
    try {
      final scheduledTime = tz.TZDateTime.from(
        napStartTime.subtract(const Duration(minutes: 15)),
        tz.local,
      );
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return; // Already passed

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'dfs_naps',
        'DFS Nap Reminders',
        channelDescription: 'Nap reminders and closures',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: 207,
        title: '🛌 Nap window closing',
        body: 'Start in the next 15 min or skip',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error scheduling nap closing reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // Reschedule all active reminders based on settings
  Future<void> updateScheduledReminders({
    required bool bedtimeEnabled,
    required String bedtime, // "HH:MM" e.g. "23:00"
    required bool caffeineEnabled,
    required String wakeTime, // "HH:MM" for caffeine calculations
    required bool checkinEnabled,
  }) async {
    // 1. Bedtime Reminders (IDs: 101, 104, 105)
    if (bedtimeEnabled) {
      // ID 101: 30 minutes before bedtime
      final parts = bedtime.split(':');
      var hr = int.parse(parts[0]);
      var min = int.parse(parts[1]) - 30;
      if (min < 0) {
        min += 60;
        hr = (hr - 1) % 24;
      }
      final bedtimeMinus30 = '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      await scheduleDailyNotification(
        id: 101,
        title: '🌙 Bedtime in 30 min',
        body: 'Start winding down to protect your sleep floor',
        timeStr: bedtimeMinus30,
      );

      // ID 104: At bedtime
      await scheduleDailyNotification(
        id: 104,
        title: '😴 Sleep window starting',
        body: 'Your sleep window starts now. Tomorrow-you will thank you',
        timeStr: bedtime,
      );

      // ID 105: 15 minutes after bedtime
      var hr15 = int.parse(parts[0]);
      var min15 = int.parse(parts[1]) + 15;
      if (min15 >= 60) {
        min15 -= 60;
        hr15 = (hr15 + 1) % 24;
      }
      final bedtimePlus15 = '${hr15.toString().padLeft(2, '0')}:${min15.toString().padLeft(2, '0')}';
      await scheduleDailyNotification(
        id: 105,
        title: '⏰ Bedtime past due',
        body: '15 min past your bedtime. Every minute counts',
        timeStr: bedtimePlus15,
      );
    } else {
      await cancelNotification(101);
      await cancelNotification(104);
      await cancelNotification(105);
    }

    // 2. Caffeine Cutoff Reminders (IDs: 102, 107)
    if (caffeineEnabled) {
      final parts = bedtime.split(':');
      var hrCutoff = (int.parse(parts[0]) - 8) % 24;
      if (hrCutoff < 0) hrCutoff += 24;
      final cutoffTimeStr = '${hrCutoff.toString().padLeft(2, '0')}:${parts[1]}';

      // ID 102: 30 minutes before caffeine cutoff
      var hr30 = hrCutoff;
      var min30 = int.parse(parts[1]) - 30;
      if (min30 < 0) {
        min30 += 60;
        hr30 = (hr30 - 1) % 24;
      }
      final cutoffMinus30 = '${hr30.toString().padLeft(2, '0')}:${min30.toString().padLeft(2, '0')}';
      await scheduleDailyNotification(
        id: 102,
        title: '🚫 Last call for caffeine!',
        body: 'Cutoff in 30 minutes',
        timeStr: cutoffMinus30,
      );

      // ID 107: At caffeine cutoff
      await scheduleDailyNotification(
        id: 107,
        title: '☕ Caffeine cutoff time',
        body: 'Caffeine cutoff at $cutoffTimeStr — 8h before bedtime',
        timeStr: cutoffTimeStr,
      );
    } else {
      await cancelNotification(102);
      await cancelNotification(107);
    }

    // 3. Check-in Reminders (IDs: 103, 106)
    if (checkinEnabled) {
      // ID 103: At wake time
      await scheduleDailyNotification(
        id: 103,
        title: "☀️ Good morning!",
        body: "How'd you sleep? (takes 10 seconds)",
        timeStr: wakeTime,
      );

      // ID 106: 2 hours after wake time
      final parts = wakeTime.split(':');
      var hr2 = (int.parse(parts[0]) + 2) % 24;
      final checkinPlus2h = '${hr2.toString().padLeft(2, '0')}:${parts[1]}';
      await scheduleDailyNotification(
        id: 106,
        title: '🔔 Log Your Sleep',
        body: "You haven't checked in yet today",
        timeStr: checkinPlus2h,
      );
    } else {
      await cancelNotification(103);
      await cancelNotification(106);
    }

    // 4. Re-engage Reminder (ID: 108)
    await scheduleReengageReminder();
  }

  // Instant Rescue Alert (ID: 201)
  Future<void> showRescueNotification(double hours) async {
    await showInstantNotification(
      id: 201,
      title: '🔴 Rescue Mode Active',
      body: 'You logged ${_formatHours(hours)} — Rescue Mode has your recovery plan',
    );
  }

  // Instant Streak Alert (ID: 202)
  Future<void> showStreakNotification(int streak, {bool isMilestone = false}) async {
    if (isMilestone) {
      await showInstantNotification(
        id: 202,
        title: '🔥 Real Habit Built',
        body: '$streak-day sleep floor streak! Building a real habit',
      );
    } else {
      await showInstantNotification(
        id: 202,
        title: '🟢 Streak Maintained',
        body: '$streak-day streak above your sleep floor! Keep it up',
      );
    }
  }

  // Instant Bounce Back Alert (ID: 203)
  Future<void> showBounceBackNotification(double hours) async {
    await showInstantNotification(
      id: 203,
      title: '💪 Bounced Back!',
      body: 'Bounced back — ${_formatHours(hours)} after two rough nights',
    );
  }

  // Instant Safety Warning (ID: 204)
  Future<void> showSafetyNotification() async {
    await showInstantNotification(
      id: 204,
      title: '🔴 Safety Counselor Warning',
      body: 'Under 4h for 3+ days — please consider talking to a counselor',
    );
  }

  // Instant Insight Alert (ID: 205)
  Future<void> showInsightNotification(String insightPreview) async {
    await showInstantNotification(
      id: 205,
      title: '📊 New sleep insight ready',
      body: 'New insight: $insightPreview. Tap to see more',
    );
  }

  // Instant Nap Alert (ID: 206)
  Future<void> showNapNotification(String duration, String time) async {
    await showInstantNotification(
      id: 206,
      title: '💤 Perfect Nap Window',
      body: 'You have a $duration gap at $time — perfect for a nap',
    );
  }

  String _formatHours(double hrs) {
    final h = hrs.floor();
    final m = ((hrs - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

final notificationService = NotificationService();
