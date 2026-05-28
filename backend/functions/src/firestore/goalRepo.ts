import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { Goal } from './schemas';

const db = admin.firestore();

export async function createGoal(userId: string, data: Omit<Goal, 'goalId' | 'createdAt' | 'userId'>): Promise<string> {
  const docRef = await db.collection('goals').add({
    ...data,
    userId,
    createdAt: FieldValue.serverTimestamp()
  });
  return docRef.id;
}

export async function getGoals(userId: string): Promise<Goal[]> {
  const snapshot = await db.collection('goals')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map(doc => ({
    goalId: doc.id,
    ...(doc.data() as Omit<Goal, 'goalId'>)
  }));
}
