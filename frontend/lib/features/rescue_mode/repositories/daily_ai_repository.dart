import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_ai_snapshot.dart';

class DailyAiRepository {
  Future<DailyAiSnapshot?> getTodaySnapshot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('rescueSessions')
          .where('userId', isEqualTo: user.uid)
          .where('calendarContextDate', isEqualTo: todayStr)
          .orderBy('triggeredAt', descending: true)
          .limit(1)
          .get();

      if (sessionsSnapshot.docs.isEmpty) {
        return null;
      }

      final doc = sessionsSnapshot.docs.first;
      final geminiResponse = doc.data()['geminiResponse'];
      if (geminiResponse is! Map) {
        return null;
      }

      return DailyAiSnapshot(
        sessionId: doc.id,
        date: todayStr,
        raw: geminiResponse.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

final dailyAiRepository = DailyAiRepository();
