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

### GET `/sleepHistory`
Mengambil histori log tidur dan agregat (summary) dari pengguna selama beberapa hari terakhir.

**Request Query Params:**
- `userId` (string)
- `days` (number, opsional, default: 30)

**Response Data Payload:**
```json
{
  "logs": [
    {
      "date": "2025-07-15",
      "durationMinutes": 420,
      "quality": 4,
      "bedtime": "23:00",
      "wakeTime": "06:00"
    }
  ],
  "summary": {
    "avgDurationMinutes": 410,
    "avgQuality": 3.5,
    "totalLogs": 14,
    "longestSleep": 480,
    "shortestSleep": 360
  }
}
```

### POST `/scheduleItem`
Menyimpan jadwal manual harian (untuk pengguna tanpa kalender terhubung).

**Request Body:**
```json
{
  "userId": "string",
  "title": "string",
  "startTime": "2025-07-15T09:00:00Z",
  "endTime": "2025-07-15T11:00:00Z",
  "date": "2025-07-15"
}
```

### GET `/scheduleItems`
Mengambil daftar jadwal manual pada tanggal tertentu. Query Params: `userId` dan `date`.

### POST `/generateSchedulePlan`
Menggunakan AI untuk menyusun `goals` ke dalam sela-sela jadwal manual atau kalender, sambil menghormati waktu tidur (sleep window). Menghasilkan `scheduleItems` secara otomatis.

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
  "plannedItems": [
    {
      "itemId": "string",
      "title": "Learn Flutter",
      "startTime": "2025-07-15T14:00:00Z",
      "endTime": "2025-07-15T15:00:00Z"
    }
  ],
  "advice": "string"
}
```

## Bagian 4: User Lifecycle (Alur Onboarding)
1. **Register**: Klien melakukan sign-up menggunakan Firebase Auth (Google atau Email). *Backend* (trigger `onUserCreate`) otomatis membuat dokumen di koleksi `userProfiles`.
2. **Onboarding Questions**: Klien memperbarui dokumen di `userProfiles` untuk atribut `morningTirednessFrequency`, `usualSleepDuration`, dan `sleepHabits`. Set `onboardingCompleted: true`.
3. **Sleep Settings**: Klien mengatur *sleep floor* dan *wake window* (`preferredBedtime`, `preferredWakeTime`) pada profil. Set `settingsCompleted: true`.
4. **Daily**: Klien mengisi `dailyCheckins` (di UI awal) dan `sleepLogs`.
5. **On demand**: Panggil `/rescuePlan`, `/dailyInsight`, `/generateSchedulePlan`, atau `/syncCalendar`.

## Bagian 5: Auth & Notifikasi Lanjutan
- **Google Auth**: Login dengan Google ditangani sepenuhnya di *client-side* Flutter. Gunakan dependensi `firebase_auth` dan `google_sign_in`. Backend hanya merespons *trigger* setelah Firebase Auth mencatatkan UID baru.
- **Notifikasi Pintar**: Pesan notifikasi dari `/rescuePlan` dan `/dailyInsight` seperti ("Avoid big meals", "Last call for caffeine", "Schedule conflict") di-jadwalkan oleh Laras secara lokal menggunakan **Local Notifications plugin** di Flutter. Hal ini lebih andal daripada push notifications jarak jauh dari server.



## Bagian 6: Apa yang TIDAK BOLEH dikirim oleh Laras (Klien)

- *API key* Gemini atau kredensial Google Service Account mana pun.
- Properti `stressScore` pada `CalendarEvents` (hanya dihitung oleh server).
- Properti `inputSnapshot` atau `geminiResponse` pada `RescueSessions`.
- Mengubah properti `calendarConnected` secara langsung ke `UserProfile`.
