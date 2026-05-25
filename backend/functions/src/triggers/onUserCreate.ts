import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

// Gunakan v1 auth trigger karena lebih stabil dan tidak memerlukan Firebase Identity Platform (Blocking Functions)
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    const db = admin.firestore();

    let firstName = '';
    let lastName = '';

    // Handle Google Sign-In (displayName tersedia) maupun Email/Password (displayName null)
    if (user.displayName) {
      const parts = user.displayName.trim().split(' ');
      firstName = parts[0] || '';
      lastName = parts.slice(1).join(' ') || '';
    }

    // Menggunakan Admin SDK: dijamin membypass firestore.rules
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

    console.log(`✅ [onUserCreate] userProfile berhasil dibuat untuk UID: ${user.uid}`);
  } catch (error) {
    console.error('🔥 [onUserCreate] ERROR:', error);
  }
});