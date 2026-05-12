import * as admin from 'firebase-admin';
import { SleepLog } from './schemas';

const db = admin.firestore();

export interface SleepProfileSummary {
  avgDurationMinutes: number;
  avgQuality: number;
  avgBedtimeHour: number;
  totalLogsCount: number;
}

/**
 * Membuat catatan tidur (sleep log) baru untuk pengguna.
 */
export async function createSleepLog(userId: string, data: Omit<SleepLog, 'logId' | 'createdAt'>): Promise<string> {
  const docRef = await db.collection('sleepLogs').add({
    ...data,
    userId,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return docRef.id;
}

/**
 * Mengambil catatan tidur pengguna dalam rentang waktu tertentu.
 * Ini adalah fungsi utama pengganti retriever RAG. Mengembalikan data diurutkan berdasarkan tanggal secara menurun (DESC).
 * Digunakan oleh promptBuilder untuk menyuntikkan konteks tidur selama 14 hari terakhir.
 */
export async function getSleepLogsByRange(userId: string, startDate: string, endDate: string): Promise<SleepLog[]> {
  const snapshot = await db.collection('sleepLogs')
    .where('userId', '==', userId)
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .orderBy('date', 'desc')
    .get();

  return snapshot.docs.map(doc => ({
    logId: doc.id,
    ...(doc.data() as Omit<SleepLog, 'logId'>)
  }));
}

/**
 * Menghitung profil tidur agregat (rata-rata) selama beberapa hari terakhir.
 */
export async function getAggregatedSleepProfile(userId: string, days: number): Promise<SleepProfileSummary> {
  const limitDate = new Date();
  limitDate.setDate(limitDate.getDate() - days);
  const startDateStr = limitDate.toISOString().split('T')[0];
  const endDateStr = new Date().toISOString().split('T')[0];

  const logs = await getSleepLogsByRange(userId, startDateStr, endDateStr);

  if (logs.length === 0) {
    return {
      avgDurationMinutes: 0,
      avgQuality: 0,
      avgBedtimeHour: 0,
      totalLogsCount: 0
    };
  }

  let totalDuration = 0;
  let totalQuality = 0;
  let totalBedtimeHour = 0;

  logs.forEach(log => {
    totalDuration += log.durationMinutes;
    totalQuality += log.quality;
    totalBedtimeHour += log.bedtime.toDate().getHours();
  });

  return {
    avgDurationMinutes: totalDuration / logs.length,
    avgQuality: totalQuality / logs.length,
    avgBedtimeHour: totalBedtimeHour / logs.length,
    totalLogsCount: logs.length
  };
}
