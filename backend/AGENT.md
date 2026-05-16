# Rangkuman Perjalanan Backend D.F.S

## Fase 1 — Arsitektur & Keputusan Desain
Koreksi fundamental dari Vector RAG ke **Context Injection** — data skalar (durasi tidur, energi 1–5) tidak butuh embedding, cukup di-inject langsung sebagai JSON ke system prompt Gemini.

## Fase 2 — Fondasi Database
Membangun seluruh layer Firestore: `schemas.ts`, `sleepRepo.ts`, `checkinRepo.ts`, `embeddingRepo.ts` (stub), security rules, composite indexes, dan `DATA_CONTRACT.md` sebagai kontrak dengan Laras.

## Fase 3 — AI Pipeline (5 File Inti)

| File | Peran |
|---|---|
| `retriever.ts` | Mengumpulkan data 14 hari dari Firestore |
| `promptBuilder.ts` | Merakit konteks → string JSON untuk Gemini |
| `rescuePlan.ts` | Controller: retriever → prompt → Gemini → response |
| `dailyInsight.ts` | Controller kedua dengan pola sama |
| `index.ts` | Entry point, register semua endpoint |

## Fase 4 — Debug & Resolusi Bug

**Bug 1** — `package.json` tidak punya `"build": "tsc"` → tambahkan script build
**Bug 2** — `tsconfig.json` tidak punya `"rootDir": "src"` → tambahkan rootDir
**Bug 3** — `firebase.json` menunjuk ke `firestore.rules` yang tidak ada di root → perbaiki path ke `firestore/firestore.rules`
**Bug 4** — `firestore/firestore.indexes.json` kosong → isi dengan composite index untuk `sleepLogs` dan `dailyCheckins`
**Bug 5** — Data hilang setiap restart emulator → tambahkan flag `--import` dan `--export-on-exit`
**Bug 6** — `admin.firestore.Timestamp.fromDate()` undefined → ganti import ke `import { Timestamp } from 'firebase-admin/firestore'`
**Bug 7** — `catch` block menelan semua error tanpa log → tambahkan `console.error` untuk visibility
**Bug 8** — Gemini API key terikat project billing-enabled → ganti ke key baru dari AI Studio dengan model `gemini-2.5-flash`
**Bug 9** — `admin.firestore.FieldValue.serverTimestamp()` undefined → ganti import ke `import { FieldValue } from 'firebase-admin/firestore'`

### Hasil Akhir

```json
// POST /rescuePlan → 200 OK (11 detik)
{
  "success": true,
  "data": {
    "checklistItems": [...],
    "sleepWindowSuggestion": { ... },
    "caffeineAdvice": "..."
  }
}
```

---

## Status Keseluruhan Proyek

| Komponen | Status |
|---|---|
| Firestore Schema & Repos | ✅ Done |
| Security Rules & Indexes | ✅ Done |
| DATA_CONTRACT.md | ✅ Done |
| `retriever.ts` | ✅ Done |
| `promptBuilder.ts` | ✅ Done |
| `/rescuePlan` endpoint | ✅ Tested & Working |
| `/dailyInsight` endpoint | ✅ Built, belum ditest |
| `/syncCalendar` endpoint | ⬜ Belum dibuat |
| Google Calendar OAuth | ⬜ Belum dibuat |
