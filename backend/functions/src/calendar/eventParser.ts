import { calendar_v3 } from 'googleapis';

export interface ParsedCalendarEvent {
  googleEventId: string;
  title: string;
  startTime: Date;
  endTime: Date;
  durationMinutes: number;
  isAllDay: boolean;
  description: string;
}

/**
 * Parse raw Google Calendar API event list response
 */
export function parseCalendarEvents(
  rawEvents: calendar_v3.Schema$Event[],
  startDate: string, // YYYY-MM-DD
  endDate: string    // YYYY-MM-DD
): ParsedCalendarEvent[] {
  try {
    const startRange = new Date(`${startDate}T00:00:00Z`);
    const endRange = new Date(`${endDate}T23:59:59Z`);

    const parsed: ParsedCalendarEvent[] = [];

    for (const ev of rawEvents) {
      // Filter out declined events
      const isDeclined = ev.attendees?.some(a => a.self && a.responseStatus === 'declined');
      if (isDeclined) continue;

      const isAllDay = !!ev.start?.date;
      
      let start: Date;
      let end: Date;

      if (isAllDay) {
        start = new Date(ev.start!.date!);
        end = ev.end?.date ? new Date(ev.end.date) : start;
      } else {
        if (!ev.start?.dateTime) continue; // Skip events with no start time
        start = new Date(ev.start.dateTime);
        end = ev.end?.dateTime ? new Date(ev.end.dateTime) : start;
      }

      // Filter by given date range
      if (end < startRange || start > endRange) continue;

      let durationMinutes = 0;
      if (!isAllDay) {
        durationMinutes = Math.round((end.getTime() - start.getTime()) / 60000);
      } else {
        durationMinutes = Math.round((end.getTime() - start.getTime()) / 60000) || 1440;
      }

      parsed.push({
        googleEventId: ev.id!,
        title: ev.summary || 'Untitled Event',
        startTime: start,
        endTime: end,
        durationMinutes,
        isAllDay,
        description: ev.description || ''
      });
    }

    return parsed;
  } catch (error) {
    console.error("🔥 [parseCalendarEvents] ERROR:", error);
    return [];
  }
}
