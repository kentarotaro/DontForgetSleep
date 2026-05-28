import { onRequest } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { GoogleGenAI } from '@google/genai';
import { getUserProfile } from '../firestore/userRepo';
import { getScheduleItemsByDate, createScheduleItem } from '../firestore/scheduleRepo';
import { getGoals } from '../firestore/goalRepo';
import { buildSchedulePlanPrompt } from '../gemini/promptBuilder';

export const generateSchedulePlan = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'POST') { res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' }); return; }

  const { userId, date } = req.body;

  // Normalisasi format tanggal ke YYYY-MM-DD murni
  // Mencegah duplikasi jadwal jika Flutter mengirim full ISO string
  const safeDate = (date as string)?.split('T')[0];

  if (!userId || !safeDate) { res.status(400).json({ success: false, code: 'MISSING_FIELD' }); return; }

  try {
    const db = admin.firestore();

    // ♻️ CEK CACHE: Apakah jadwal AI untuk userId + tanggal ini sudah pernah di-generate hari ini?
    // Penting: mencegah Gemini dipanggil berkali-kali DAN mencegah duplikasi item di scheduleItems
    const cacheSnapshot = await db.collection('schedulePlanCache')
      .where('userId', '==', userId)
      .where('date', '==', safeDate)
      .limit(1)
      .get();

    if (!cacheSnapshot.empty) {
      const cached = cacheSnapshot.docs[0].data();
      console.log(`♻️ [generateSchedulePlan] Mengembalikan CACHE untuk userId: ${userId}, tanggal: ${safeDate}`);
      res.status(200).json({
        success: true,
        data: {
          plannedItems: cached.plannedItems,
          advice: cached.advice
        }
      });
      return;
    }

    const profile = await getUserProfile(userId);
    if (!profile) { res.status(404).json({ success: false, code: 'NOT_FOUND' }); return; }

    const schedules = await getScheduleItemsByDate(userId, safeDate);
    const goals = await getGoals(userId);

    const prompt = buildSchedulePlanPrompt(profile, schedules, goals, safeDate);

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("🔥 [generateSchedulePlan] ERROR:", "GEMINI_API_KEY not found");
      res.status(500).json({ success: false, code: 'SERVER_ERROR' });
      return;
    }

    const ai = new GoogleGenAI({ apiKey });
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt.userMessage,
      config: {
        systemInstruction: prompt.systemInstruction,
        responseMimeType: "application/json"
      }
    });

    const responseText = response.text;
    let planObj: any;
    try {
      planObj = JSON.parse(responseText || '{}');
    } catch (e) {
      console.error("🔥 [generateSchedulePlan] ERROR:", "Failed to parse Gemini JSON", responseText, e);
      res.status(502).json({ success: false, code: 'GEMINI_UNAVAILABLE' });
      return;
    }

    // Simpan item jadwal ke Firestore (hanya sekali, karena cache sudah dicek di atas)
    const createdItems: any[] = [];
    if (planObj.plannedItems && Array.isArray(planObj.plannedItems)) {
      for (const item of planObj.plannedItems) {
        const itemId = await createScheduleItem(userId, {
          title: item.title,
          startTime: item.startTime,
          endTime: item.endTime,
          date: safeDate,
          isFromGoogleCalendar: false
        });
        createdItems.push({ itemId, ...item });
      }
    }

    // Simpan cache agar request berikutnya di hari yang sama tidak perlu memanggil Gemini lagi
    void db.collection('schedulePlanCache').add({
      userId,
      date: safeDate,
      plannedItems: createdItems,
      advice: planObj.advice || '',
      generatedAt: FieldValue.serverTimestamp()
    });

    res.status(200).json({
      success: true,
      data: {
        plannedItems: createdItems,
        advice: planObj.advice
      }
    });
  } catch (error: any) {
    console.error("🔥 [generateSchedulePlan] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR' });
  }
});
