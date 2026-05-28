import { onRequest } from "firebase-functions/v2/https";
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
  if (!userId || !date) { res.status(400).json({ success: false, code: 'MISSING_FIELD' }); return; }

  try {
    const profile = await getUserProfile(userId);
    if (!profile) { res.status(404).json({ success: false, code: 'NOT_FOUND' }); return; }

    const schedules = await getScheduleItemsByDate(userId, date);
    const goals = await getGoals(userId);

    const prompt = buildSchedulePlanPrompt(profile, schedules, goals, date);

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

    const createdItems = [];
    if (planObj.plannedItems && Array.isArray(planObj.plannedItems)) {
      for (const item of planObj.plannedItems) {
        const itemId = await createScheduleItem(userId, {
          title: item.title,
          startTime: item.startTime,
          endTime: item.endTime,
          date,
          isFromGoogleCalendar: false
        });
        createdItems.push({ itemId, ...item });
      }
    }

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
