import { Timestamp } from 'firebase-admin/firestore';

/**
 * Data profil utama pengguna.
 */
export interface UserProfile {
  userId: string;
  name: string;
  chronotype: 'morning' | 'evening' | 'intermediate';
  targetSleepHours: number;
  calendarConnected: boolean;
  createdAt: Timestamp;
}

/**
 * Merepresentasikan satu sesi tidur yang dicatat oleh pengguna.
 * 
 * // CATATAN ARSITEKTUR: TIDAK ADA field embedding. Ini disengaja.
 * // Data skalar/relasional akan disuntikkan (injected) langsung ke dalam konteks prompt.
 */
export interface SleepLog {
  logId?: string; // ID otomatis dari Firestore
  userId: string;
  date: string; // Format YYYY-MM-DD, diindeks untuk query rentang waktu
  bedtime: Timestamp;
  wakeTime: Timestamp;
  durationMinutes: number;
  quality: 1 | 2 | 3 | 4 | 5;
  createdAt: Timestamp;
}

/**
 * Laporan harian subjektif pengguna mengenai suasana hati (mood) dan energi.
 * 
 * // CATATAN ARSITEKTUR: TIDAK ADA field embedding. Ini disengaja.
 * // Data skalar/relasional akan disuntikkan (injected) langsung ke dalam konteks prompt.
 */
export interface DailyCheckin {
  checkinId?: string; // ID otomatis dari Firestore
  userId: string;
  date: string; // Format YYYY-MM-DD, diindeks
  energyLevel: 1 | 2 | 3 | 4 | 5;
  caffeineIntakeMg: number;
  mood: 'great' | 'good' | 'neutral' | 'bad' | 'terrible';
  notes?: string; // Catatan opsional singkat, maks 280 karakter — TIDAK di-embed pada MVP
  createdAt: Timestamp;
}

/**
 * Acara kalender yang disinkronkan dari Google Calendar.
 */
export interface CalendarEvent {
  eventId?: string;
  userId: string;
  googleEventId: string;
  title: string;
  startTime: Timestamp;
  endTime: Timestamp;
  stressScore: number; // Nilai 0.0–1.0, dihitung oleh stressScorer.ts
  syncedAt: Timestamp;
}

/**
 * Hasil (output) dari Rescue Plan yang dihasilkan AI.
 */
export interface RescueSession {
  sessionId?: string;
  userId: string;
  triggeredAt: Timestamp;
  inputSnapshot: object; // Data payload asli yang dikirim ke Gemini, untuk audit
  geminiResponse: object; // Hasil (output) format JSON yang sudah di-parse dari Gemini
  calendarContextDate: string; // Tanggal konteks kalender format YYYY-MM-DD
}
