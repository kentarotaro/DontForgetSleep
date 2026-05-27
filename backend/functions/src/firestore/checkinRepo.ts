import * as admin from 'firebase-admin';
import { DailyCheckin } from './schemas';

const db = admin.firestore();

/**
 * Membuat catatan laporan harian (daily check-in) baru.
 */
export async function createCheckin(userId: string, data: Omit<DailyCheckin, 'checkinId' | 'createdAt'>): Promise<string> {
  const docRef = await db.collection('dailyCheckins').add({
    ...data,
    userId,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return docRef.id;
}

/**
 * Mengambil catatan harian terbaru dari seorang pengguna.
 * Mengembalikan data diurutkan berdasarkan tanggal menurun (DESC). Bawaan (default) rentang hari = 14.
 * Digunakan oleh promptBuilder untuk menyusun konteks tren energi/kafein.
 */
export async function getRecentCheckins(userId: string, days: number = 14): Promise<DailyCheckin[]> {
  const limitDate = new Date();
  limitDate.setDate(limitDate.getDate() - days);
  const startDateStr = limitDate.toISOString().split('T')[0];
  const endDateStr = new Date().toISOString().split('T')[0];

  const snapshot = await db.collection('dailyCheckins')
    .where('userId', '==', userId)
    .where('date', '>=', startDateStr)
    .where('date', '<=', endDateStr)
    .orderBy('date', 'desc')
    .get();

  return snapshot.docs.map(doc => ({
    checkinId: doc.id,
    ...(doc.data() as Omit<DailyCheckin, 'checkinId'>)
  }));
}

/**
 * Mengambil catatan harian berdasarkan tanggal tertentu.
 */
export async function getCheckinByDate(userId: string, date: string): Promise<DailyCheckin | null> {
  const snapshot = await db.collection('dailyCheckins')
    .where('userId', '==', userId)
    .where('date', '==', date)
    .limit(1)
    .get();

  if (snapshot.empty) return null;

  const doc = snapshot.docs[0];
  return {
    checkinId: doc.id,
    ...(doc.data() as Omit<DailyCheckin, 'checkinId'>)
  };
}
