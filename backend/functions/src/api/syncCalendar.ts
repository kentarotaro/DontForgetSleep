import { onRequest } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { getAuthenticatedCalendarClient } from '../calendar/calendarClient';
import { parseCalendarEvents } from '../calendar/eventParser';
import { scoreEvent } from '../calendar/stressScorer';

export const syncCalendar = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED', message: 'Hanya menerima POST' });
    return;
  }

  const { userId, dateRange } = req.body;

  if (!userId || !dateRange || !dateRange.start || !dateRange.end) {
    res.status(400).json({
      success: false,
      code: 'MISSING_FIELD',
      message: 'userId dan dateRange (start, end) harus disertakan'
    });
    return;
  }

  try {
    const calendar = await getAuthenticatedCalendarClient(userId);
    if (!calendar) {
      res.status(400).json({
        success: false,
        code: 'CALENDAR_NOT_CONNECTED',
        message: 'Kalender Google belum dihubungkan. Hubungkan terlebih dahulu.'
      });
      return;
    }

    const response = await calendar.events.list({
      calendarId: 'primary',
      timeMin: new Date(`${dateRange.start}T00:00:00+07:00`).toISOString(),
      timeMax: new Date(`${dateRange.end}T23:59:59+07:00`).toISOString(),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 50
    });

    const rawEvents = response.data.items || [];
    const parsedEvents = parseCalendarEvents(rawEvents, dateRange.start, dateRange.end);

    const db = admin.firestore();
    const batch = db.batch();
    const highStressEvents: { title: string, date: string, stressScore: number }[] = [];

    for (const ev of parsedEvents) {
      const stressScore = scoreEvent(ev);

      const docRef = db.collection('calendarEvents').doc(ev.googleEventId);
      batch.set(docRef, {
        userId,
        googleEventId: ev.googleEventId,
        title: ev.title,
        startTime: Timestamp.fromDate(ev.startTime),
        endTime: Timestamp.fromDate(ev.endTime),
        stressScore,
        syncedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      if (stressScore >= 0.5) {
        highStressEvents.push({
          title: ev.title,
          date: ev.startTime.toISOString().split('T')[0],
          stressScore
        });
      }
    }

    const userRef = db.collection('userProfiles').doc(userId);
    batch.set(userRef, { calendarConnected: true }, { merge: true });

    await batch.commit();

    res.status(200).json({
      success: true,
      data: {
        syncedCount: parsedEvents.length,
        highStressEvents
      }
    });

  } catch (error: any) {
    console.error("🔥 [syncCalendar] ERROR:", error);
    res.status(500).json({
      success: false,
      code: 'SERVER_ERROR',
      message: 'Terjadi kesalahan pada server'
    });
  }
});
