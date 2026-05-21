import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  
  let firstName = '';
  let lastName = '';
  
  if (user.displayName) {
    const parts = user.displayName.split(' ');
    firstName = parts[0] || '';
    lastName = parts.slice(1).join(' ') || '';
  }

  await db.collection('userProfiles').doc(user.uid).set({
    userId: user.uid,
    firstName,
    lastName,
    email: user.email || '',
    calendarConnected: false,
    onboardingCompleted: false,
    settingsCompleted: false,
    createdAt: FieldValue.serverTimestamp()
  });
});
