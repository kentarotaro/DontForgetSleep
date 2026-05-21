import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { ScheduleItem } from './schemas';

const db = admin.firestore();

export async function createScheduleItem(userId: string, data: Omit<ScheduleItem, 'itemId' | 'createdAt' | 'userId'>): Promise<string> {
  const docRef = await db.collection('scheduleItems').add({
    ...data,
    userId,
    createdAt: FieldValue.serverTimestamp()
  });
  return docRef.id;
}

export async function getScheduleItemsByDate(userId: string, date: string): Promise<ScheduleItem[]> {
  const snapshot = await db.collection('scheduleItems')
    .where('userId', '==', userId)
    .where('date', '==', date)
    .orderBy('startTime', 'asc')
    .get();

  return snapshot.docs.map(doc => ({
    itemId: doc.id,
    ...(doc.data() as Omit<ScheduleItem, 'itemId'>)
  }));
}

export async function getScheduleItemsByRange(userId: string, startDate: string, endDate: string): Promise<ScheduleItem[]> {
  const snapshot = await db.collection('scheduleItems')
    .where('userId', '==', userId)
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .orderBy('date', 'asc')
    .orderBy('startTime', 'asc')
    .get();

  return snapshot.docs.map(doc => ({
    itemId: doc.id,
    ...(doc.data() as Omit<ScheduleItem, 'itemId'>)
  }));
}
