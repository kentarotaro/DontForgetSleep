import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/sleep_history_store.dart';
import '../models/sleep_entry.dart';

class FirestoreSleepHistoryStore implements SleepHistoryStore {
  final List<SleepEntry> _entries = [];

  FirestoreSleepHistoryStore() {
    loadEntries();
  }

  Future<List<SleepEntry>> loadEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sleepLogs')
          .where('userId', isEqualTo: user.uid)
          .get();

      _entries.clear();
      for (final doc in snapshot.docs) {
        _entries.add(_fromFirestore(doc));
      }
      _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching sleep logs from Firestore: $e');
    }
    return _entries;
  }

  SleepEntry _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime startTime;
    final startVal = data['bedtime'];
    if (startVal is Timestamp) {
      startTime = startVal.toDate();
    } else if (startVal is String) {
      startTime = DateTime.parse(startVal);
    } else {
      startTime = DateTime.now();
    }

    DateTime endTime;
    final endVal = data['wakeTime'];
    if (endVal is Timestamp) {
      endTime = endVal.toDate();
    } else if (endVal is String) {
      endTime = DateTime.parse(endVal);
    } else {
      endTime = DateTime.now();
    }

    final typeString = data['type'] as String?;
    final type = typeString == 'nap' ? SleepType.nap : SleepType.nightSleep;

    return SleepEntry(
      id: doc.id,
      startTime: startTime,
      endTime: endTime,
      type: type,
      quality: data['quality'] ?? 3,
      notes: data['notes'] as String?,
    );
  }

  @override
  List<SleepEntry> seedEntries() {
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> addSleepEntry(SleepEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';
    final docId = 'sleep_${user.uid}_$dateStr';
    final docRef = FirebaseFirestore.instance.collection('sleepLogs').doc(docId);

    await docRef.set({
      'userId': user.uid,
      'date': dateStr,
      'bedtime': Timestamp.fromDate(entry.startTime),
      'wakeTime': Timestamp.fromDate(entry.endTime),
      'durationMinutes': entry.duration.inMinutes,
      'quality': entry.quality,
      'notes': entry.notes ?? '',
      'type': entry.type == SleepType.nap ? 'nap' : 'nightSleep',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final entryWithId = entry.copyWith(id: docId);
    final exists = _entries.any((e) => e.id == entryWithId.id);
    if (!exists) {
      _entries.add(entryWithId);
      _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
  }

  @override
  Future<void> updateSleepEntry(SleepEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('sleepLogs').doc(entry.id);
    final dateStr = '${entry.endTime.year}-${entry.endTime.month.toString().padLeft(2, '0')}-${entry.endTime.day.toString().padLeft(2, '0')}';

    await docRef.update({
      'date': dateStr,
      'bedtime': Timestamp.fromDate(entry.startTime),
      'wakeTime': Timestamp.fromDate(entry.endTime),
      'durationMinutes': entry.duration.inMinutes,
      'quality': entry.quality,
      'notes': entry.notes ?? '',
      'type': entry.type == SleepType.nap ? 'nap' : 'nightSleep',
    });

    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = entry;
      _entries.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
  }
}
