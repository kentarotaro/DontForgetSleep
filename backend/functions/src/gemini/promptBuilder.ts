import { UserSleepContext } from '../context/retriever';

export interface BuiltPrompt {
  systemInstruction: string;
  userMessage: string;
}

/**
 * Membangun prompt untuk fitur Rescue Plan
 */
export function buildRescuePrompt(
  context: UserSleepContext,
  currentEnergyLevel: number,
  currentSleepDebtMinutes: number
): BuiltPrompt {
  const systemInstruction = `You are an empathetic sleep coach and expert in sleep science. Your goal is to help the user optimize their sleep without being alarmist.
HARD CONSTRAINT: You are NOT a medical doctor. Never diagnose medical conditions.
OUTPUT FORMAT: You MUST respond with a valid JSON object only.

Follow this exact JSON schema for your response:
{
  "checklistItems": [
    { "id": "string", "action": "string", "durationMinutes": 0, "priority": "high|medium|low" }
  ],
  "sleepWindowSuggestion": {
    "recommendedBedtime": "HH:MM",
    "recommendedWakeTime": "HH:MM",
    "reasoning": "string"
  },
  "caffeineAdvice": "string"
}`;

  // Filter 7 days
  const last7DaysSleep = context.sleepLogs.slice(0, 7).map(log => ({
    date: log.date,
    durationMinutes: log.durationMinutes,
    quality: log.quality
  }));

  const last7DaysCheckins = context.recentCheckins.slice(0, 7).map(chk => ({
    date: chk.date,
    energyLevel: chk.energyLevel,
    caffeineIntakeMg: chk.caffeineIntakeMg,
    mood: chk.mood
  }));

  const todayEvents = context.calendarEvents
    .filter(ev => {
        try {
            return ev.startTime.toDate().toISOString().startsWith(context.queryDate);
        } catch(e) {
            return false;
        }
    })
    .map(ev => ({
      title: ev.title,
      stressScore: ev.stressScore
    }));

  const contextData = {
    sleepLogs: last7DaysSleep,
    checkins: last7DaysCheckins,
    sleepProfile: {
      avgDurationMinutes: context.sleepProfile.avgDurationMinutes,
      avgQuality: context.sleepProfile.avgQuality,
      avgBedtimeHour: context.sleepProfile.avgBedtimeHour
    },
    todayEvents,
    currentStatus: {
      currentEnergyLevel,
      currentSleepDebtMinutes
    }
  };

  const userMessage = `Based on the following user context, generate a personalized rescue plan.

User Context Data:
${JSON.stringify(contextData, null, 2)}

Based on the above context, generate a rescue plan.`;

  return { systemInstruction, userMessage };
}

/**
 * Membangun prompt untuk fitur Daily Insight
 */
export function buildDailyInsightPrompt(
  context: UserSleepContext
): BuiltPrompt {
  const systemInstruction = `You are an empathetic sleep coach and expert in sleep science. Your goal is to help the user optimize their sleep without being alarmist.
HARD CONSTRAINT: You are NOT a medical doctor. Never diagnose medical conditions.
OUTPUT FORMAT: You MUST respond with a valid JSON object only.

Follow this exact JSON schema for your response:
{
  "insightTitle": "string",
  "insightBody": "string",
  "trendTag": "improving|stable|declining",
  "recommendation": "string",
  "dataPointsUsed": 0
}

Instructions for dataPointsUsed: Count the total number of sleep logs and check-in entries you analyzed from the context and return that integer.`;

  const contextData = {
    sleepLogs: context.sleepLogs.map(log => ({
      date: log.date,
      durationMinutes: log.durationMinutes,
      quality: log.quality
    })),
    checkins: context.recentCheckins.map(chk => ({
      date: chk.date,
      energyLevel: chk.energyLevel,
      caffeineIntakeMg: chk.caffeineIntakeMg,
      mood: chk.mood
    })),
    sleepProfile: context.sleepProfile,
    calendarEvents: context.calendarEvents.map(ev => {
      try {
        return {
          title: ev.title,
          stressScore: ev.stressScore,
          date: ev.startTime.toDate().toISOString().split('T')[0]
        };
      } catch(e) {
        return { title: ev.title, stressScore: ev.stressScore, date: '' };
      }
    })
  };

  const userMessage = `Based on the following 14-day user context, generate a daily insight.

User Context Data:
${JSON.stringify(contextData, null, 2)}

Analyze the trends over the last 14 days and provide today's insight.`;

  return { systemInstruction, userMessage };
}
