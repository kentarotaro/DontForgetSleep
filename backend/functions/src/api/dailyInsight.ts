import { onRequest } from "firebase-functions/v2/https";

import { GoogleGenAI } from '@google/genai';
import { buildUserSleepContext } from '../context/retriever';
import { buildDailyInsightPrompt } from '../gemini/promptBuilder';

export const dailyInsight = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED', message: 'Hanya menerima POST' });
    return;
  }

  const { userId, date } = req.body;

  if (!userId || !date) {
    res.status(400).json({
      success: false,
      code: 'MISSING_FIELD',
      message: 'userId dan date harus disertakan'
    });
    return;
  }

  try {
    const context = await buildUserSleepContext(userId, date);

    if (context.sleepLogs.length < 5) {
      res.status(400).json({
        success: false,
        code: 'INSUFFICIENT_SLEEP_DATA',
        message: 'Data tidur tidak mencukupi untuk insight. Butuh minimal 5 catatan.'
      });
      return;
    }

    const prompt = buildDailyInsightPrompt(context);

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
       console.error("GEMINI_API_KEY tidak ditemukan di environment variables");
       res.status(500).json({ success: false, code: 'SERVER_ERROR', message: 'Konfigurasi server salah' });
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

    let geminiResponseObj;
    try {
      geminiResponseObj = JSON.parse(responseText || '{}');
    } catch (e) {
      console.error("Gagal melakukan parsing JSON dari Gemini", responseText);
      res.status(502).json({
        success: false,
        code: 'GEMINI_UNAVAILABLE',
        message: 'Respon Gemini tidak dapat diuraikan'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: geminiResponseObj
    });
  } catch (error: any) {
    console.error("Error di dailyInsight:", error);
    res.status(500).json({
      success: false,
      code: 'SERVER_ERROR',
      message: 'Terjadi kesalahan pada server'
    });
  }
});
