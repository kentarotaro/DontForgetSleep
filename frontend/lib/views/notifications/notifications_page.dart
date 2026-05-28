import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/theme/typography.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _hideFocusCard = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: Text('Please sign in to view notifications.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dailyCheckins')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, checkinsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('sleepLogs')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, sleepSnapshot) {
            final notifications = _buildDynamicNotifications(
              checkinsSnapshot.data?.docs ?? const [],
              sleepSnapshot.data?.docs ?? const [],
            );
            final unreadCount = notifications.where((item) => item.isUnread).length;
            final sleepAlerts = notifications.where((item) => item.category == 'Sleep').length;
            final scheduleAlerts = notifications.where((item) => item.category == 'Schedule').length;

            return Scaffold(
              backgroundColor: AppColors.scaffoldBg,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryHeader(unreadCount, sleepAlerts, scheduleAlerts),
                      if (!_hideFocusCard) ...[
                        const SizedBox(height: 20),
                        _buildFocusCard(onClose: () => setState(() => _hideFocusCard = true)),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'TODAY',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.purple500,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (notifications.isEmpty)
                        _buildEmptyState()
                      else
                        ...notifications.map(_buildNotificationCard),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryHeader(int unreadCount, int sleepAlerts, int scheduleAlerts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151124),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple900, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.purple950,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.purple300,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stay in sync with your sleep floor', style: AppTextStyles.itemTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      unreadCount == 0
                          ? 'You are all caught up for now.'
                          : '$unreadCount unread updates need your attention.',
                      style: AppTextStyles.itemMeta,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildMetricPill(
                label: 'Sleep',
                value: '$sleepAlerts ${sleepAlerts == 1 ? 'alert' : 'alerts'}',
                color: AppColors.teal,
                backgroundColor: const Color(0x142DD4A8),
              ),
              const SizedBox(width: 10),
              _buildMetricPill(
                label: 'Schedule',
                value: '$scheduleAlerts ${scheduleAlerts == 1 ? 'update' : 'updates'}',
                color: AppColors.purple300,
                backgroundColor: const Color(0x14301E48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.itemMeta.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.itemTitle.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard({required VoidCallback onClose}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12212A), Color(0xFF171427)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0E3A43), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x1A00D8BF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF00D8BF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiet, useful, and sleep-first', style: AppTextStyles.itemTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  'These alerts are designed to protect your sleep floor and avoid noisy notifications.',
                  style: AppTextStyles.itemMeta.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple900, width: 1),
      ),
      child: Text('No updates yet. Your reminders will appear here.', style: AppTextStyles.itemMeta),
    );
  }

  Widget _buildNotificationCard(_NotificationItem item) {
    final accent = item.accentColor;
    final borderColor = item.isUnread ? accent : AppColors.purple900;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: AppTextStyles.itemTitle.copyWith(fontSize: 15)),
                    ),
                    if (item.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.body, style: AppTextStyles.itemMeta.copyWith(height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x140D0618),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(item.category, style: AppTextStyles.itemMeta.copyWith(color: accent)),
                    ),
                    const SizedBox(width: 8),
                    Text(item.timeLabel, style: AppTextStyles.itemMeta),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_NotificationItem> _buildDynamicNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> checkins,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sleepLogs,
  ) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final hasTodayCheckin = checkins.any((doc) => (doc.data()['date']?.toString() ?? '') == todayStr);
    final sortedSleepLogs = [...sleepLogs]
      ..sort((a, b) {
        final aDate = a.data()['date']?.toString() ?? '';
        final bDate = b.data()['date']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });

    double? latestHours;
    if (sortedSleepLogs.isNotEmpty) {
      final latest = sortedSleepLogs.first.data();
      final durationMinutes = latest['durationMinutes'] as num?;
      if (durationMinutes != null) {
        latestHours = durationMinutes / 60.0;
      }
    }

    final items = <_NotificationItem>[];

    if (!hasTodayCheckin) {
      items.add(
        const _NotificationItem(
          title: 'Morning check-in is ready',
          body: 'Log how long you slept and your energy level so today\'s insight stays accurate.',
          category: 'Check-in',
          timeLabel: 'Now',
          icon: Icons.wb_sunny_outlined,
          accentColor: Color(0xFF00D8BF),
          isUnread: true,
        ),
      );
    }

    if (latestHours != null) {
      if (latestHours < 7.0) {
        items.add(
          _NotificationItem(
            title: 'Rescue guidance is available',
            body: 'You slept ${latestHours.toStringAsFixed(1)}h last night. Rescue Mode is ready with recovery guidance.',
            category: 'Sleep',
            timeLabel: 'Today',
            icon: Icons.shield_outlined,
            accentColor: AppColors.red300,
            isUnread: true,
          ),
        );
      } else {
        items.add(
          _NotificationItem(
            title: 'Sleep floor protected',
            body: 'Great consistency. You slept ${latestHours.toStringAsFixed(1)}h and stayed above your floor target.',
            category: 'Sleep',
            timeLabel: 'Today',
            icon: Icons.check_circle_outline,
            accentColor: AppColors.teal,
          ),
        );
      }
    }

    items.add(
      const _NotificationItem(
        title: 'Schedule is ready to sync',
        body: 'Open Schedule tab to update your week based on current sleep context.',
        category: 'Schedule',
        timeLabel: 'Today',
        icon: Icons.calendar_today_outlined,
        accentColor: AppColors.purple300,
      ),
    );

    return items;
  }
}

class _NotificationItem {
  final String title;
  final String body;
  final String category;
  final String timeLabel;
  final IconData icon;
  final Color accentColor;
  final bool isUnread;

  const _NotificationItem({
    required this.title,
    required this.body,
    required this.category,
    required this.timeLabel,
    required this.icon,
    required this.accentColor,
    this.isUnread = false,
  });
}
