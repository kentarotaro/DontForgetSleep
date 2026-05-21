import * as admin from 'firebase-admin';

// Initialize Firebase Admin App
admin.initializeApp();

// Export Cloud Functions

/**
 * Endpoint: POST /rescuePlan
 * Generates a personalized rescue plan for the user when they need help sleeping.
 */
export { rescuePlan } from './api/rescuePlan';

/**
 * Endpoint: POST /dailyInsight
 * Fetches a personalized daily insight based on the user's recent sleep, check-ins, and calendar.
 */
export { dailyInsight } from './api/dailyInsight';

/**
 * Endpoint: POST /syncCalendar
 * Triggers a manual sync of the user's Google Calendar events to update their stress scores.
 */
export { syncCalendar } from './api/syncCalendar';

/**
 * Endpoint: GET /oauthCallback
 * Menerima callback dari Google OAuth untuk sinkronisasi Calendar.
 */
export { oauthCallback } from './api/oauthCallback';

export { onUserCreate } from './triggers/onUserCreate';
export { sleepHistory } from './api/sleepHistory';
export { scheduleItemCreate, scheduleItemList, goalItemCreate, goalItemList } from './api/scheduleItem';
export { generateSchedulePlan } from './api/generateSchedulePlan';
