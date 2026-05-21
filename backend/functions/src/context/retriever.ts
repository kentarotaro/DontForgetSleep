import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { SleepLog, DailyCheckin, CalendarEvent, UserProfile } from '../firestore/schemas';
import { getSleepLogsByRange, getAggregatedSleepProfile, SleepProfileSummary } from '../firestore/sleepRepo';
import { getRecentCheckins, getCheckinByDate } from '../firestore/checkinRepo';
import { getUserProfile } from '../firestore/userRepo';
import { getScheduleItemsByRange } from '../firestore/scheduleRepo';

/**
 * Konteks data pengguna untuk disuntikkan ke prompt Gemini.
 */
export interface UserSleepContext {
  userId: string;
  queryDate: string; // YYYY-MM-DD
  userProfile: UserProfile | null;
  sleepLogs: SleepLog[];             // last 14 days, ordered DESC
  recentCheckins: DailyCheckin[];    // last 14 days, ordered DESC  
  sleepProfile: SleepProfileSummary; // aggregated stats
  todayCheckin: DailyCheckin | null; // today's check-in if exists
  calendarEvents: CalendarEvent[];   // events for queryDate ± 1 day
}

/**
 * Membangun objek konteks pengguna untuk dikirim ke Gemini.
 */
export async function buildUserSleepContext(
  userId: string,
  queryDate: string
): Promise<UserSleepContext> {
  try {
    const sleepLogs = await getSleepLogsByRange(userId, getPastDateStr(queryDate, 14), queryDate);
    const recentCheckins = await getRecentCheckins(userId, 14);
    const sleepProfile = await getAggregatedSleepProfile(userId, 14);
    const todayCheckin = await getCheckinByDate(userId, queryDate);
    const userProfile = await getUserProfile(userId);

    // Hitung tanggal untuk calendar events
    const yesterdayStr = getPastDateStr(queryDate, 1);
    const tomorrowStr = getFutureDateStr(queryDate, 1);

    // Konversi ke Date object untuk query timestamp
    const startTimeLimit = new Date(`${yesterdayStr}T00:00:00Z`);
    const endTimeLimit = new Date(`${tomorrowStr}T23:59:59Z`);

    let calendarEvents: CalendarEvent[] = [];

    if (userProfile?.calendarConnected) {
      const db = admin.firestore();
      const calendarSnapshot = await db.collection('calendarEvents')
        .where('userId', '==', userId)
        .where('startTime', '>=', Timestamp.fromDate(startTimeLimit))
        .where('startTime', '<=', Timestamp.fromDate(endTimeLimit))
        .get();

      calendarEvents = calendarSnapshot.docs.map(doc => ({
        eventId: doc.id,
        ...(doc.data() as Omit<CalendarEvent, 'eventId'>)
      }));
    } else {
      const scheduleItems = await getScheduleItemsByRange(userId, yesterdayStr, tomorrowStr);
      calendarEvents = scheduleItems.map(item => ({
        eventId: item.itemId,
        userId: item.userId,
        googleEventId: 'manual',
        title: item.title,
        startTime: Timestamp.fromDate(new Date(item.startTime)),
        endTime: Timestamp.fromDate(new Date(item.endTime)),
        stressScore: 0.3,
        syncedAt: item.createdAt
      }));
    }

    return {
      userId,
      queryDate,
      userProfile,
      sleepLogs,
      recentCheckins,
      sleepProfile,
      todayCheckin,
      calendarEvents
    };
  } catch (error) {
    console.error("🔥 BONGKAR ERROR FIRESTORE:", error);
    // Mengembalikan array kosong secara elegan jika ada kegagalan fungsi dasar (graceful empty-data handling)
    return {
      userId,
      queryDate,
      userProfile: null,
      sleepLogs: [],
      recentCheckins: [],
      sleepProfile: { avgDurationMinutes: 0, avgQuality: 0, avgBedtimeHour: 0, totalLogsCount: 0 },
      todayCheckin: null,
      calendarEvents: []
    };
  }
}

// Helper dates
function getPastDateStr(baseDate: string, daysToSubtract: number): string {
  const d = new Date(`${baseDate}T00:00:00Z`);
  d.setDate(d.getDate() - daysToSubtract);
  return d.toISOString().split('T')[0];
}

function getFutureDateStr(baseDate: string, daysToAdd: number): string {
  const d = new Date(`${baseDate}T00:00:00Z`);
  d.setDate(d.getDate() + daysToAdd);
  return d.toISOString().split('T')[0];
}
