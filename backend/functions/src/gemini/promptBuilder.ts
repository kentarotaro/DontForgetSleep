import { UserSleepContext } from '../context/retriever';
import { UserProfile, ScheduleItem, Goal } from '../firestore/schemas';

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
    sleepHabits: context.userProfile?.sleepHabits || [],
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

/**
 * Membangun prompt untuk fitur Generate Schedule Plan
 */
export function buildSchedulePlanPrompt(
  profile: UserProfile,
  schedules: ScheduleItem[],
  goals: Goal[],
  date: string
): BuiltPrompt {
  const systemInstruction = `You are a highly efficient productivity coach and time-management expert.
Your task is to generate a time-blocked daily schedule that integrates the user's fixed schedules and their goals, while strictly respecting their sleep window.

HARD CONSTRAINT: NEVER schedule any tasks during the user's sleep window.
OUTPUT FORMAT: You MUST respond with a valid JSON object only.

Follow this exact JSON schema:
{
  "plannedItems": [
    {
      "title": "string",
      "startTime": "YYYY-MM-DDTHH:MM:SSZ",
      "endTime": "YYYY-MM-DDTHH:MM:SSZ"
    }
  ],
  "advice": "string"
}`;

  const sleepWindow = {
    preferredBedtime: profile.preferredBedtime || "22:00",
    preferredWakeTime: profile.preferredWakeTime || "06:00",
    targetSleepHours: profile.targetSleepHours || 8,
    sleepFloorHours: profile.sleepFloorHours || 6
  };

  const existingSchedules = schedules.map(s => ({
    title: s.title,
    startTime: s.startTime,
    endTime: s.endTime
  }));

  const goalsToSchedule = goals.map(g => ({
    title: g.title,
    estimatedMinutes: g.estimatedMinutes,
    priority: g.priority
  }));

  const userMessage = `Generate a schedule plan for ${date}.
  
User Sleep Window Constraints:
${JSON.stringify(sleepWindow, null, 2)}

Existing Fixed Schedules (do not reschedule these):
${JSON.stringify(existingSchedules, null, 2)}

Goals to Schedule:
${JSON.stringify(goalsToSchedule, null, 2)}

Instructions:
1. Try to schedule the goals into the free blocks of time.
2. Respect the sleep window (do not schedule anything between preferredBedtime and preferredWakeTime).
3. Return the new planned items (only the goals you scheduled). Ensure startTime and endTime are valid ISO strings for ${date}.
`;

  return { systemInstruction, userMessage };
}
