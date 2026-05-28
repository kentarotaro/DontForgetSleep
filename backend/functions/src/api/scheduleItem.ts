import { onRequest } from "firebase-functions/v2/https";
import { createScheduleItem, getScheduleItemsByDate } from '../firestore/scheduleRepo';
import { createGoal, getGoals } from '../firestore/goalRepo';

export const scheduleItemCreate = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'POST') { res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' }); return; }

  const { userId, title, startTime, endTime, date } = req.body;
  if (!userId || !title || !startTime || !endTime || !date) {
    res.status(400).json({ success: false, code: 'MISSING_FIELD' });
    return;
  }

  try {
    const itemId = await createScheduleItem(userId, {
      title, startTime, endTime, date, isFromGoogleCalendar: false
    });
    res.status(200).json({ success: true, data: { itemId } });
  } catch (error: any) {
    console.error("🔥 [scheduleItemCreate] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR' });
  }
});

export const scheduleItemList = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'GET') { res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' }); return; }

  const userId = req.query.userId as string;
  const date = req.query.date as string;
  if (!userId || !date) { res.status(400).json({ success: false, code: 'MISSING_FIELD' }); return; }

  try {
    const items = await getScheduleItemsByDate(userId, date);
    res.status(200).json({ success: true, data: { items } });
  } catch (error: any) {
    console.error("🔥 [scheduleItemList] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR' });
  }
});

export const goalItemCreate = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'POST') { res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' }); return; }

  const { userId, title, estimatedMinutes, priority } = req.body;
  if (!userId || !title || estimatedMinutes == null || !priority) {
    res.status(400).json({ success: false, code: 'MISSING_FIELD' });
    return;
  }

  try {
    const goalId = await createGoal(userId, { title, estimatedMinutes, priority });
    res.status(200).json({ success: true, data: { goalId } });
  } catch (error: any) {
    console.error("🔥 [goalItemCreate] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR' });
  }
});

export const goalItemList = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'GET') { res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' }); return; }

  const userId = req.query.userId as string;
  if (!userId) { res.status(400).json({ success: false, code: 'MISSING_FIELD' }); return; }

  try {
    const goals = await getGoals(userId);
    res.status(200).json({ success: true, data: { goals } });
  } catch (error: any) {
    console.error("🔥 [goalItemList] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR' });
  }
});
