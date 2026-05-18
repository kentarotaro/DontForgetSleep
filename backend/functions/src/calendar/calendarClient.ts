import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { google, calendar_v3 } from 'googleapis';

const db = admin.firestore();

interface CalendarTokens {
  accessToken: string;
  refreshToken: string;
  expiryDate: number;
}

/**
 * Retrieve stored OAuth tokens for a user from Firestore
 */
export async function getCalendarTokens(userId: string): Promise<CalendarTokens | null> {
  try {
    const doc = await db.collection('userProfiles').doc(userId).collection('privateData').doc('calendarTokens').get();
    if (!doc.exists) return null;
    return doc.data() as CalendarTokens;
  } catch (error) {
    console.error("🔥 [getCalendarTokens] ERROR:", error);
    return null;
  }
}

/**
 * Save/update OAuth tokens for a user to Firestore
 */
export async function saveCalendarTokens(userId: string, tokens: CalendarTokens): Promise<void> {
  try {
    const docRef = db.collection('userProfiles').doc(userId).collection('privateData').doc('calendarTokens');
    await docRef.set({
      ...tokens,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  } catch (error) {
    console.error("🔥 [saveCalendarTokens] ERROR:", error);
    throw error;
  }
}

/**
 * Build an authenticated Google Calendar API client for a user
 */
export async function getAuthenticatedCalendarClient(userId: string): Promise<calendar_v3.Calendar | null> {
  try {
    const tokens = await getCalendarTokens(userId);
    if (!tokens) return null;

    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    oauth2Client.setCredentials({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      expiry_date: tokens.expiryDate
    });

    // Auto-refresh token if expired
    oauth2Client.on('tokens', async (newTokens) => {
      try {
        const updatedTokens: CalendarTokens = {
          accessToken: newTokens.access_token || tokens.accessToken,
          refreshToken: newTokens.refresh_token || tokens.refreshToken,
          expiryDate: newTokens.expiry_date || tokens.expiryDate
        };
        await saveCalendarTokens(userId, updatedTokens);
      } catch (err) {
        console.error("🔥 [oauth2Client.on(tokens)] ERROR:", err);
      }
    });

    return google.calendar({ version: 'v3', auth: oauth2Client });
  } catch (error) {
    console.error("🔥 [getAuthenticatedCalendarClient] ERROR:", error);
    return null;
  }
}

/**
 * Exchange OAuth authorization code for tokens
 */
export async function exchangeCodeForTokens(code: string): Promise<CalendarTokens> {
  try {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    const { tokens } = await oauth2Client.getToken(code);
    return {
      accessToken: tokens.access_token!,
      refreshToken: tokens.refresh_token!,
      expiryDate: tokens.expiry_date!
    };
  } catch (error) {
    console.error("🔥 [exchangeCodeForTokens] ERROR:", error);
    throw error;
  }
}
