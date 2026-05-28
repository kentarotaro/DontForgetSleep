import { UserSleepContext } from '../context/retriever';
import { UserProfile, ScheduleItem, Goal } from '../firestore/schemas';

export interface BuiltPrompt {
  systemInstruction: string;
  userMessage: string;
}

/**
 * Membangun prompt untuk fitur Rescue Plan
 * Schema dirancang agar setiap field langsung bisa di-render sebagai widget Flutter
 * tanpa parsing tambahan di sisi frontend.
 */
export function buildRescuePrompt(
  context: UserSleepContext,
  currentEnergyLevel: number,
  currentSleepDebtMinutes: number
): BuiltPrompt {
  const schema = `{
  "checklistItems": [
    {
      "id": "task_1",
      "action": "Take a 20-minute power nap before 3 PM.",
      "durationMinutes": 20,
      "priority": "high",
      "isDone": false
    },
    {
      "id": "task_2",
      "action": "Do 5 minutes of light stretching now.",
      "durationMinutes": 5,
      "priority": "medium",
      "isDone": false
    }
  ],
  "sleepWindowSuggestion": {
    "recommendedBedtime": "22:00",
    "recommendedWakeTime": "06:00",
    "reasoningTitle": "Earlier Bedtime",
    "reasoningDetails": "Earlier bedtime helps recover sleep debt within one cycle."
  },
  "caffeineAdvice": {
    "shouldAvoidCaffeine": true,
    "caffeineCutoffTime": "13:00",
    "tips": [
      "Switch to herbal tea after cutoff time.",
      "Avoid energy drinks today."
    ]
  }
}`;

  const systemInstruction = [
    'You are an empathetic sleep coach and expert in sleep science.',
    'HARD CONSTRAINT: You are NOT a medical doctor. Never diagnose medical conditions.',
    'HARD CONSTRAINT: Output ONLY a valid JSON object. No markdown, no code fences, no prose.',
    '',
    'Your response MUST follow this exact schema (the example below is also the template):',
    schema,
    '',
    'Rules:',
    '- Produce 3 to 5 checklistItems.',
    '- Each action must be SHORT and ACTIONABLE. Max 12 words per action.',
    '- Each caffeineAdvice.tips entry must be SHORT. Max 10 words each.',
    '- reasoningTitle must be max 5 words.',
    '- reasoningDetails must be ONE sentence, max 15 words.',
    '- isDone must always be false.',
    '- Do NOT wrap the response in markdown code blocks.',
  ].join('\n');

  // Filter to last 7 days of data
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
      } catch (e) {
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

  const userMessage = [
    'Based on the user sleep context below, generate a personalized rescue plan.',
    'Your response MUST be a single valid JSON object. Output ONLY the JSON, nothing else.',
    '',
    'User Context Data:',
    JSON.stringify(contextData, null, 2),
    '',
    'Generate the rescue plan now.',
  ].join('\n');

  return { systemInstruction, userMessage };
}

/**
 * Membangun prompt untuk fitur Daily Insight
 */
export function buildDailyInsightPrompt(
  context: UserSleepContext
): BuiltPrompt {
  const systemInstruction = [
    'You are an empathetic sleep coach and expert in sleep science.',
    'HARD CONSTRAINT: You are NOT a medical doctor. Never diagnose medical conditions.',
    'HARD CONSTRAINT: Output ONLY a valid JSON object. No markdown, no code fences, no prose.',
    '',
    'You MUST respond with a valid JSON object following this exact schema:',
    '{',
    '  "insightTitle": "string (max 8 words)",',
    '  "insightBody": "string (2-3 sentences, concise summary of sleep trend)",',
    '  "trendTag": "improving" | "stable" | "declining",',
    '  "recommendation": "string (ONE actionable sentence, max 15 words)",',
    '  "dataPointsUsed": 0',
    '}',
    '',
    'Instructions for dataPointsUsed: Count the total number of sleep logs and check-in entries analyzed.',
    'Do NOT wrap the response in markdown code blocks.',
  ].join('\n');

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
      } catch (e) {
        return { title: ev.title, stressScore: ev.stressScore, date: '' };
      }
    })
  };

  const userMessage = [
    'Based on the following 14-day user context, generate a daily sleep insight.',
    'Your response MUST be a single valid JSON object. Output ONLY the JSON, nothing else.',
    '',
    'User Context Data:',
    JSON.stringify(contextData, null, 2),
    '',
    'Analyze the trends over the last 14 days and provide today\'s insight.',
  ].join('\n');

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
  const systemInstruction = [
    'You are a highly efficient productivity coach and time-management expert.',
    'Your task is to generate a time-blocked daily schedule that integrates fixed schedules and goals, while strictly respecting the sleep window.',
    '',
    'HARD CONSTRAINT: NEVER schedule any tasks during the user\'s sleep window.',
    'HARD CONSTRAINT: Output ONLY a valid JSON object. No markdown, no code fences, no prose.',
    '',
    'You MUST respond with a valid JSON object following this exact schema:',
    '{',
    '  "plannedItems": [',
    '    {',
    '      "title": "string",',
    '      "startTime": "YYYY-MM-DDTHH:MM:SSZ",',
    '      "endTime": "YYYY-MM-DDTHH:MM:SSZ"',
    '    }',
    '  ],',
    '  "advice": "string (ONE sentence summary, max 20 words)"',
    '}',
  ].join('\n');

  const sleepWindow = {
    preferredBedtime: profile.preferredBedtime || '22:00',
    preferredWakeTime: profile.preferredWakeTime || '06:00',
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

  const userMessage = [
    `Generate a schedule plan for ${date}.`,
    'Your response MUST be a single valid JSON object. Output ONLY the JSON, nothing else.',
    '',
    'User Sleep Window Constraints:',
    JSON.stringify(sleepWindow, null, 2),
    '',
    'Existing Fixed Schedules (do not reschedule these):',
    JSON.stringify(existingSchedules, null, 2),
    '',
    'Goals to Schedule:',
    JSON.stringify(goalsToSchedule, null, 2),
    '',
    'Instructions:',
    '1. Schedule the goals into free time blocks.',
    '2. NEVER place any task between preferredBedtime and preferredWakeTime.',
    `3. All startTime and endTime values must be valid ISO strings for the date ${date}.`,
  ].join('\n');

  return { systemInstruction, userMessage };
}
