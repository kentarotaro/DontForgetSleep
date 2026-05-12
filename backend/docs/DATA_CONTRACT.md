# D.F.S (Don't Forget Sleep) - Kontrak Data (Data Contract)

Dokumen ini menguraikan kontrak komunikasi antara *frontend* Flutter dan *backend* Firebase untuk fase MVP. Dokumen ini menggantikan rencana berbasis RAG sebelumnya dengan *Context Injection* (Penyuntikan Konteks).

## Bagian 1: Konvensi Umum

- **Kunci API (API Keys)**: Semua kunci JSON harus menggunakan `camelCase`.
- **Format Waktu (Timestamps)**: Semua waktu pada respons API HTTP harus menggunakan format *string* ISO 8601 (contoh: `"2025-07-14T22:30:00+07:00"`).
- **Zona Waktu**: Selalu gunakan WIB (UTC+7) untuk tampilan/respons, dan UTC untuk penyimpanan di Firestore.
- **Pembungkus Sukses (Success Envelope)**: Semua respons fungsi HTTP yang berhasil akan dibungkus dengan format:
  ```json
  {
    "success": true,
    "data": { ... }
  }
  ```
- **Pembungkus Error (Error Envelope)**: Semua respons fungsi HTTP yang gagal akan dibungkus dengan format:
  ```json
  {
    "success": false,
    "code": "KODE_ERROR",
    "message": "Pesan error yang mudah dibaca manusia"
  }
  ```
- **Daftar Kode Error**:
  - `USER_NOT_FOUND` (Pengguna tidak ditemukan)
  - `MISSING_FIELD` (Isian ada yang kurang)
  - `CALENDAR_NOT_CONNECTED` (Kalender belum terhubung)
  - `GEMINI_UNAVAILABLE` (Layanan Gemini tidak tersedia)
  - `INSUFFICIENT_SLEEP_DATA` (Data tidur tidak cukup)

## Bagian 2: Akses Langsung Firestore (Flutter SDK)

Laras (Flutter Dev) dapat membaca/menulis secara langsung ke Firestore untuk beberapa koleksi tertentu menggunakan FlutterFire SDK. Semua koleksi memiliki struktur di tingkat akar (*root level*) dan membutuhkan properti `userId` untuk dicocokkan dengan pengguna yang sedang *login* (terautentikasi).

- **`sleepLogs`**: KLIEN (Flutter) dapat membuat dan membaca dokumen miliknya sendiri.
- **`dailyCheckins`**: KLIEN (Flutter) dapat membuat dan membaca dokumen miliknya sendiri.
- **`userProfiles`**: KLIEN (Flutter) hanya dapat membaca dokumen miliknya sendiri.
- **`calendarEvents`**: KLIEN (Flutter) hanya dapat membaca (dibuat/disinkronisasi oleh *backend*).
- **`rescueSessions`**: KLIEN (Flutter) hanya dapat membaca (dibuat oleh *backend*).

## Bagian 3: Titik Akhir (Endpoints) Cloud Function

### POST `/rescuePlan`
Menghasilkan rencana pemulihan (Rescue Plan) yang dipersonalisasi ketika pengguna butuh bantuan untuk tidur.

**Request Body (Data yang dikirim):**
```json
{
  "userId": "string",
  "currentDate": "YYYY-MM-DD",
  "currentEnergyLevel": 3,
  "currentSleepDebtMinutes": 120
}
```

**Response Data Payload (Data yang dikembalikan):**
```json
{
  "checklistItems": [
    {
      "id": "string",
      "action": "string",
      "durationMinutes": 15,
      "priority": "high"
    }
  ],
  "sleepWindowSuggestion": {
    "recommendedBedtime": "22:30",
    "recommendedWakeTime": "06:30",
    "reasoning": "string"
  },
  "caffeineAdvice": "string"
}
```

### POST `/dailyInsight`
Mengambil wawasan harian (Daily Insight) berdasarkan data tidur terbaru, laporan harian (check-in), dan jadwal kalender.

**Request Body:**
```json
{
  "userId": "string",
  "date": "YYYY-MM-DD"
}
```

**Response Data Payload:**
```json
{
  "insightTitle": "string",
  "insightBody": "string",
  "trendTag": "improving",
  "recommendation": "string",
  "dataPointsUsed": 14
}
```

### POST `/syncCalendar`
Memicu sinkronisasi manual acara Google Calendar pengguna untuk memperbarui skor stres mereka.

**Request Body:**
```json
{
  "userId": "string",
  "dateRange": {
    "start": "2025-07-01",
    "end": "2025-07-31"
  }
}
```

**Response Data Payload:**
```json
{
  "syncedCount": 5,
  "highStressEvents": [
    {
      "title": "string",
      "date": "2025-07-15",
      "stressScore": 0.85
    }
  ]
}
```

## Bagian 4: Apa yang TIDAK BOLEH dikirim oleh Laras (Klien)

- *API key* Gemini atau kredensial Google Service Account mana pun.
- Properti `stressScore` pada `CalendarEvents` (hanya dihitung oleh server).
- Properti `inputSnapshot` atau `geminiResponse` pada `RescueSessions`.
- Mengubah properti `calendarConnected` secara langsung ke `UserProfile`.
