# Agent Log

## Completed Tasks
- Refactored architecture to use Context Injection instead of Vector RAG for structured sleep data.
- Rewrote `docs/DATA_CONTRACT.md` detailing exact JSON request/responses and explicit rules for Flutter developers.
- Updated `functions/src/firestore/schemas.ts` removing `embedding` fields and structuring collections correctly (`UserProfile`, `SleepLog`, `DailyCheckin`, `CalendarEvent`, `RescueSession`).
- Refactored `functions/src/firestore/sleepRepo.ts` with explicit range queries based on YYYY-MM-DD `date` strings and added an aggregated sleep profile calculator.
- Refactored `functions/src/firestore/checkinRepo.ts` with explicit range queries based on `date`.
- Rewrote `functions/src/firestore/embeddingRepo.ts` as an empty MVP stub for future unstructured data.
- Enforced strict root-level security rules in `firestore/firestore.rules` distinguishing `isOwner` and `isCreatingForSelf` logic, specifically securing fields like `calendarConnected` and `stressScore`.
- Updated `docs/FIRESTORE_SCHEMA.md` to reflect scalar fields, no embeddings, writer designations (CLIENT/FUNCTION), and updated JSON examples.

## Next Steps
- Implement logic in `api/` endpoints (e.g. `rescuePlan`, `dailyInsight`, `syncCalendar`).
- Integrate Context Injection formatting inside `rag/promptBuilder.ts`.
- Integrate actual Gemini calling code using the structured context.
