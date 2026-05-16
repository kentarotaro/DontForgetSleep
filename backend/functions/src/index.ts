import * as admin from 'firebase-admin';

// Initialize Firebase Admin App
admin.initializeApp();

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
