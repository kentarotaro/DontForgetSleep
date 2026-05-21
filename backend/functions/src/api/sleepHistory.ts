import { onRequest } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';

export const sleepHistory = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED', message: 'Hanya menerima GET' });
    return;
  }

  const userId = req.query.userId as string;
  const daysStr = req.query.days as string || '30';

  if (!userId) {
    res.status(400).json({ success: false, code: 'MISSING_FIELD', message: 'userId harus disertakan' });
    return;
  }

  const days = parseInt(daysStr, 10);
  if (isNaN(days) || days <= 0) {
    res.status(400).json({ success: false, code: 'INVALID_DAYS', message: 'Parameter days harus berupa angka positif' });
    return;
  }

  try {
    const limitDate = new Date();
    limitDate.setDate(limitDate.getDate() - days);
    const startDateStr = limitDate.toISOString().split('T')[0];

    const db = admin.firestore();
    const snapshot = await db.collection('sleepLogs')
      .where('userId', '==', userId)
      .where('date', '>=', startDateStr)
      .orderBy('date', 'desc')
      .get();

    const logs = snapshot.docs.map(doc => {
      const data = doc.data();
      const bedtimeDate = data.bedtime && typeof data.bedtime.toDate === 'function' ? data.bedtime.toDate() : new Date(data.bedtime);
      const wakeDate = data.wakeTime && typeof data.wakeTime.toDate === 'function' ? data.wakeTime.toDate() : new Date(data.wakeTime);
      
      const formatTime = (d: Date) => `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;

      return {
        date: data.date,
        durationMinutes: data.durationMinutes,
        quality: data.quality,
        bedtime: isNaN(bedtimeDate.getTime()) ? "00:00" : formatTime(bedtimeDate),
        wakeTime: isNaN(wakeDate.getTime()) ? "00:00" : formatTime(wakeDate)
      };
    });

    let totalDuration = 0;
    let totalQuality = 0;
    let longestSleep = 0;
    let shortestSleep = Infinity;

    logs.forEach(log => {
      totalDuration += log.durationMinutes;
      totalQuality += log.quality;
      if (log.durationMinutes > longestSleep) longestSleep = log.durationMinutes;
      if (log.durationMinutes < shortestSleep) shortestSleep = log.durationMinutes;
    });

    if (shortestSleep === Infinity) shortestSleep = 0;

    const totalLogs = logs.length;
    const summary = {
      avgDurationMinutes: totalLogs > 0 ? Math.round(totalDuration / totalLogs) : 0,
      avgQuality: totalLogs > 0 ? Math.round((totalQuality / totalLogs) * 10) / 10 : 0,
      totalLogs,
      longestSleep,
      shortestSleep
    };

    res.status(200).json({
      success: true,
      data: {
        logs,
        summary
      }
    });
  } catch (error: any) {
    console.error("🔥 [sleepHistory] ERROR:", error);
    res.status(500).json({ success: false, code: 'SERVER_ERROR', message: 'Terjadi kesalahan pada server' });
  }
});
