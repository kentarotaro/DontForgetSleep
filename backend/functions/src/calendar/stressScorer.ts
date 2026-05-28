import { ParsedCalendarEvent } from './eventParser';
import * as KEYWORDS from '../data/stressKeywords.json';

/**
 * Pencocokan kata kunci dengan Word Boundary (\b).
 * Mencegah "tes" match ke "tesis", "rapat" match ke "terapat", dsb.
 */
function countExactMatches(title: string, keywords: string[]): number {
  let count = 0;
  for (const kw of keywords) {
    try {
      const regex = new RegExp(`\\b${kw}\\b`, 'i');
      if (regex.test(title)) count++;
    } catch {
      // Abaikan keyword yang mengandung karakter regex invalid
    }
  }
  return count;
}

/**
 * Hitung skor stres untuk satu acara kalender (0.0 – 1.0).
 *
 * Sistem bobot bertingkat:
 * HIGH   → 0.15/kw, maks 0.40
 * MEDIUM → 0.08/kw, maks 0.24 (hanya jika HIGH = 0)
 * LIGHT  → 0.04/kw, maks 0.12
 * Durasi → 0.10 (>60 mnt) atau 0.20 (>120 mnt)
 * Waktu  → 0.10 (agak luar normal) atau 0.20 (sangat luar normal)
 */
export function scoreEvent(event: ParsedCalendarEvent): number {
  try {
    let score = 0;
    const title = event.title;

    // --- Heuristik 1: Durasi ---
    if (event.durationMinutes > 120) score += 0.2;
    else if (event.durationMinutes > 60) score += 0.1;

    // --- Heuristik 2: Kata kunci HIGH STRESS ---
    const highMatches = countExactMatches(title, KEYWORDS.high);
    // Satu kata kunci HIGH langsung memberi bobot 0.4 (sangat stres)
    score += Math.min(0.70, highMatches * 0.40);

    // --- Heuristik 3: Kata kunci MEDIUM ---
    if (highMatches === 0) {
      const mediumMatches = countExactMatches(title, KEYWORDS.medium);
      // Satu kata kunci MEDIUM memberi bobot 0.2
      score += Math.min(0.40, mediumMatches * 0.20);
    }

    // --- Heuristik 4: Kata kunci LIGHT ---
    const lightMatches = countExactMatches(title, KEYWORDS.light);
    // Kata kunci LIGHT justru bisa mengurangi stres (misal: "olahraga", "liburan")
    score -= Math.min(0.20, lightMatches * 0.10);
    // Pastikan skor tidak negatif
    score = Math.max(0, score);

    // --- Heuristik 5: Acara seharian ---
    if (event.isAllDay) score += 0.1;

    // --- Heuristik 6: Waktu di luar jam normal ---
    // Paksa konversi ke Date agar aman jika startTime/endTime
    // datang sebagai string ISO, number timestamp, atau Firestore Timestamp
    if (!event.isAllDay) {
      const startTime = new Date(event.startTime);
      const endTime = new Date(event.endTime);

      if (!isNaN(startTime.getTime()) && !isNaN(endTime.getTime())) {
        const startHour = startTime.getHours();
        const endHour = endTime.getHours();

        if (startHour < 7 || endHour >= 21) score += 0.2;
        else if (startHour < 9 || endHour >= 18) score += 0.1;
      }
    }

    return Math.min(1.0, score);
  } catch (error) {
    console.error("🔥 [scoreEvent] ERROR:", error);
    return 0.0;
  }
}

/**
 * Rata-rata skor stres dari semua acara dalam satu hari.
 */
export function computeDayStressScore(events: ParsedCalendarEvent[]): number {
  try {
    if (!events || events.length === 0) return 0.0;
    const total = events.reduce((sum, ev) => sum + scoreEvent(ev), 0);
    return Math.min(1.0, total / events.length);
  } catch (error) {
    console.error("🔥 [computeDayStressScore] ERROR:", error);
    return 0.0;
  }
}