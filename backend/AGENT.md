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

## Fase 5 — Integrasi Google Calendar & Penyelesaian Akhir

Pada fase ini, kita menutup celah integrasi kalender dan memastikan semua arsitektur tervalidasi dengan sempurna.

1. **Validasi `/dailyInsight`**: Penyesuaian `admin.firestore.FieldValue` ke impor khusus dan pengamanan *error logging* pada `dailyInsight.ts` agar seragam dengan standar proyek.
2. **Lapisan Integrasi Kalender Google**:
   - `calendarClient.ts`: Menangani otentikasi, perolehan, dan penyegaran token OAuth2 menggunakan dependensi `googleapis`.
   - `eventParser.ts`: Membersihkan respons mentah Google Calendar, menghilangkan acara yang ditolak, dan memastikannya masuk dalam rentang waktu yang relevan.
   - `stressScorer.ts`: Memproses *stress score* berdasarkan durasi, kata kunci, dan penanda *all-day* dari kalender (maksimal skala 1.0).
3. **Endpoint `/syncCalendar`**: Pengontrol yang memproses permintaan *sync*, mengambil kalender otentik pengguna, mem-*parsing* acara, menghitung tingkat stres, serta memuatnya ke koleksi `calendarEvents` di Firestore.
4. **Perbaikan Keamanan Lingkungan**: Pemutakhiran *file* `package.json` untuk dukungan `googleapis` serta templat `.env` bagi *credentials* OAuth2 Google.
5. **Lubang Arsitektur OAuth Ditutup**: Penambahan *endpoint* `/oauthCallback` (di `oauthCallback.ts`) untuk melayani balasan rujukan langsung dari persetujuan log masuk Google.
6. **Kompilasi Sukses**: TypeScript kompilasi kembali menghasilkan 0 galat (`tsc` selesai secara bersih).

## Fase 6 — Penyempurnaan Logika & Resolusi Bug Data

Fase ini berfokus pada penyempurnaan akurasi penilaian (scoring) dan penanganan tipe data lintas platform (Flutter -> Firestore).

1. **Restrukturisasi Kamus Stres**: Memindahkan kumpulan kata kunci stres ke file eksternal `stressKeywords.json` dan mengaktifkan `resolveJsonModule` di `tsconfig.json` (Pemisahan *Logic* & *Data* yang lebih bersih).
2. **Re-kalibrasi Bobot Stres (`stressScorer.ts`)**: Batas deteksi `highStressEvents` di `syncCalendar.ts` diturunkan secara logis menjadi `0.5`. Bobot kata kunci juga dinaikkan (HIGH = 0.4, MEDIUM = 0.2, LIGHT = -0.1) agar algoritma dapat menangkap acara bertekanan tinggi secara lebih realistis.
3. **Resolusi Type Mismatch (`sleepRepo.ts`)**: Mencegah *crash* akibat pemanggilan `.toDate()` pada data `bedtime` yang dikirim sebagai ISO String oleh klien. Menambahkan fungsi helper `toJsDate` yang kebal terhadap berbagai tipe (`Date`, `Timestamp`, `string`) serta menolak nilai *falsy* untuk menghindari pencemaran data agregat.
4. **Data Patching (Emulator)**: Menulis *script* injeksi Node.js (`patch_firestore.js`) untuk memperbaiki dokumen `sleepLogs` yang kehilangan data `bedtime` dan `wakeTime` tanpa perlu antarmuka visual (UI).
5. **Log Diagnostik Sementara**: Menyuntikkan instruksi log (`context.sleepLogs.length`) pada `dailyInsight.ts` guna memastikan bahwa dokumen yang masuk sudah memenuhi syarat kuantitas minimum sebelum diumpankan ke Gemini.

---

## Status Keseluruhan Proyek Terkini

| Komponen | Status |
|---|---|
| Firestore Schema & Repos | ✅ Done |
| Security Rules & Indexes | ✅ Done |
| DATA_CONTRACT.md | ✅ Done |
| `retriever.ts` | ✅ Done |
| `promptBuilder.ts` | ✅ Done |
| `/rescuePlan` endpoint | ✅ Tested & Working |
| `/dailyInsight` endpoint | ✅ Built & Verified |
| `/syncCalendar` endpoint | ✅ Built & Verified |
| Google Calendar OAuth | ✅ Built (`oauthCallback` Ready) |
