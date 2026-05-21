import * as admin from 'firebase-admin';
import { UserProfile } from './schemas';

const db = admin.firestore();

export async function createUserProfile(userId: string, data: Omit<UserProfile, 'userId'>): Promise<void> {
  await db.collection('userProfiles').doc(userId).set({
    ...data,
    userId
  });
}

export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  const doc = await db.collection('userProfiles').doc(userId).get();
  if (!doc.exists) return null;
  return doc.data() as UserProfile;
}

export async function updateOnboarding(
  userId: string, 
  answers: Pick<UserProfile, 'morningTirednessFrequency' | 'usualSleepDuration' | 'sleepHabits'>
): Promise<void> {
  await db.collection('userProfiles').doc(userId).update({
    ...answers,
    onboardingCompleted: true
  });
}

export async function updateSettings(
  userId: string,
  settings: Pick<UserProfile, 'sleepFloorHours' | 'preferredWakeTime' | 'preferredBedtime'>
): Promise<void> {
  await db.collection('userProfiles').doc(userId).update({
    ...settings,
    settingsCompleted: true
  });
}
