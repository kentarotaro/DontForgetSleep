import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import 'sleep_preferences_service.dart';

class CalendarSyncResult {
  final bool success;
  final String message;

  const CalendarSyncResult({required this.success, required this.message});
}

class CalendarSyncService {
  Timer? _pollingTimer;
  int _pollingAttempts = 0;

  Future<CalendarSyncResult> connectCalendar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const CalendarSyncResult(
        success: false,
        message: 'Please log in first.',
      );
    }

    final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id':
          '224581222595-mlvevh46vhgbc7c8btk2bedlgcn3q5cl.apps.googleusercontent.com',
      'redirect_uri': ApiEndpoints.oauthCallback,
      'response_type': 'code',
      'scope': 'https://www.googleapis.com/auth/calendar.readonly',
      'state': uid,
      'access_type': 'offline',
      'prompt': 'consent',
    });

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      return const CalendarSyncResult(
        success: false,
        message: 'Could not open Google OAuth page.',
      );
    }

    final connected = await _startConnectionPolling(uid);
    if (!connected) {
      return const CalendarSyncResult(
        success: false,
        message:
            'Calendar connection did not complete. This account may not be allowed yet.',
      );
    }

    return const CalendarSyncResult(
      success: true,
      message: 'Google Calendar connected successfully.',
    );
  }

  Future<bool> _attemptSilentSync(String uid) async {
    try {
      final now = DateTime.now();
      final startStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final end = now.add(const Duration(days: 7));
      final endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final result = await ApiClient.postSyncCalendar({
        'userId': uid,
        'dateRange': {'start': startStr, 'end': endStr},
      });

      return result['success'] ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _startConnectionPolling(String uid) async {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;

    final completer = Completer<bool>();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      _pollingAttempts++;
      if (_pollingAttempts > 15) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return;
      }

      final success = await _attemptSilentSync(uid);
      if (success) {
        timer.cancel();
        await sleepPreferencesService.loadFromFirestore(uid);
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        return;
      }

      await sleepPreferencesService.loadFromFirestore(uid);
      if (sleepPreferencesService.calendarConnected) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    return completer.future;
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
