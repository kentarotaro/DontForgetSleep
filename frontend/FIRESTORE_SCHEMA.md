# Dokumentasi Skema Firestore

Dokumen ini mendefinisikan skema untuk database Firestore aplikasi D.F.S.

## Catatan Arsitektur: Properti yang Sengaja Dihilangkan
TIDAK ADA properti vektor `embedding` dalam koleksi mana pun untuk versi MVP ini. Catatan tidur dan laporan harian (check-in) berisi data skalar/relasional (durasi tidur, skala energi, jumlah kafein). Mengubahnya menjadi *embedding* dengan dimensi tinggi tidak memberikan nilai semantik apa pun, memperlambat proses pemanggilan API Gemini, dan membuang memori. Oleh karena itu, kita akan menggunakan *Context Injection* (Penyuntikan Konteks).

## Koleksi (Collections)

### `userProfiles`
**Path:** `/userProfiles/{userId}`

| Properti (Field) | Tipe | Penulis | Deskripsi |
|------------------|------|---------|-------------|
| `userId` | string | KEDUANYA | ID pengguna (Primary) |
| `name` | string | KLIEN | Nama pengguna |
| `chronotype` | string | KLIEN | 'morning' \| 'evening' \| 'intermediate' |
| `targetSleepHours` | number | KLIEN | Target jam tidur harian |
| `calendarConnected` | boolean | FUNGSI | Hanya dikelola secara ketat oleh *backend* |
| `createdAt` | timestamp | KEDUANYA | Waktu pembuatan dokumen |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "name": "Kenta",
  "chronotype": "morning",
  "targetSleepHours": 8,
  "calendarConnected": true,
  "createdAt": "2023-10-25T07:05:00Z"
}
```

### `sleepLogs`
**Path:** `/sleepLogs/{logId}`

| Properti (Field) | Tipe | Penulis | Deskripsi |
|------------------|------|---------|-------------|
| `userId` | string | KLIEN | Pemilik catatan tidur |
| `date` | string | KLIEN | Format YYYY-MM-DD |
| `bedtime` | timestamp | KLIEN | Waktu mulai tidur |
| `wakeTime` | timestamp | KLIEN | Waktu bangun tidur |
| `durationMinutes` | number | KLIEN | Total durasi tidur dalam menit |
| `quality` | number | KLIEN | Kualitas tidur (skala 1-5) |
| `createdAt` | timestamp | KEDUANYA | Waktu pembuatan dokumen |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "date": "2023-10-24",
  "bedtime": "2023-10-24T23:00:00Z",
  "wakeTime": "2023-10-25T07:00:00Z",
  "durationMinutes": 480,
  "quality": 4,
  "createdAt": "2023-10-25T07:05:00Z"
}
```

### `dailyCheckins`
**Path:** `/dailyCheckins/{checkinId}`

| Properti (Field) | Tipe | Penulis | Deskripsi |
|------------------|------|---------|-------------|
| `userId` | string | KLIEN | Pemilik laporan (check-in) |
| `date` | string | KLIEN | Format YYYY-MM-DD |
| `energyLevel` | number | KLIEN | Tingkat energi (skala 1-5) |
| `caffeineIntakeMg` | number | KLIEN | Jumlah asupan kafein (mg) |
| `mood` | string | KLIEN | 'great' \| 'good' \| 'neutral' \| 'bad' \| 'terrible' |
| `notes` | string | KLIEN | Catatan opsional singkat (maks 280 karakter) |
| `createdAt` | timestamp | KEDUANYA | Waktu pembuatan dokumen |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "date": "2023-10-25",
  "energyLevel": 3,
  "caffeineIntakeMg": 150,
  "mood": "neutral",
  "notes": "Feeling okay, need coffee",
  "createdAt": "2023-10-25T08:00:00Z"
}
```

### `calendarEvents`
**Path:** `/calendarEvents/{eventId}`

| Properti (Field) | Tipe | Penulis | Deskripsi |
|------------------|------|---------|-------------|
| `userId` | string | FUNGSI | Pemilik acara |
| `googleEventId`| string | FUNGSI | ID asli acara dari Google |
| `title` | string | FUNGSI | Judul acara kalender |
| `startTime` | timestamp | FUNGSI | Waktu mulai acara |
| `endTime` | timestamp | FUNGSI | Waktu selesai acara |
| `stressScore` | number | FUNGSI | Skor stres yang dihitung otomatis (0.0 - 1.0) |
| `syncedAt` | timestamp | FUNGSI | Waktu terakhir disinkronisasi |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "googleEventId": "event_abc",
  "title": "Meeting",
  "startTime": "2023-10-25T10:00:00Z",
  "endTime": "2023-10-25T11:00:00Z",
  "stressScore": 0.75,
  "syncedAt": "2023-10-25T09:00:00Z"
}
```

### `rescueSessions`
**Path:** `/rescueSessions/{sessionId}`

| Properti (Field) | Tipe | Penulis | Deskripsi |
|------------------|------|---------|-------------|
| `userId` | string | FUNGSI | Pemilik sesi |
| `triggeredAt` | timestamp | FUNGSI | Waktu eksekusi sesi |
| `inputSnapshot` | object | FUNGSI | Data aslinya yang dikirim ke Gemini |
| `geminiResponse`| object | FUNGSI | Balasan JSON dari Gemini. Format mengikuti `/rescuePlan`, termasuk `checklistItems`, `sleepWindowSuggestion`, dan `caffeineAdvice` object |
| `calendarContextDate` | string | FUNGSI | Tanggal konteks (YYYY-MM-DD) |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "triggeredAt": "2023-10-26T00:00:00Z",
  "inputSnapshot": {"energy": 2, "sleepDebt": 120},
  "geminiResponse": {
    "checklistItems": [],
    "sleepWindowSuggestion": {
      "recommendedBedtime": "22:00",
      "recommendedWakeTime": "06:00"
    },
    "caffeineAdvice": {
      "tips": ["Switch to decaf or herbal tea after noon."],
      "caffeineCutoffTime": "13:00",
      "shouldAvoidCaffeine": true
    }
  },
  "calendarContextDate": "2023-10-26"
}
```

## Kebutuhan Indeks (Index Requirements)

Indeks gabungan (Composite Indexes) berikut ini diwajibkan (karena dibutuhkan oleh query `date-range`):

- **`sleepLogs`**: `userId` (Naik/ASC), `date` (Turun/DESC)
- **`dailyCheckins`**: `userId` (Naik/ASC), `date` (Turun/DESC)


rescuePlan 
curl -X POST https://generatescheduleplan-v4gtcfan5q-uc.a.run.app#post2 \
     -H "Content-Type: application/json" \
     -d '{
  "userId": "DZd26hxPpnYo9HEf2Pal9fnnmCo1",
  "currentDate": "2026-05-28",
  "currentEnergyLevel": 3,
  "cur


  {
  "data": {
    "caffeineAdvice": {
      "tips": [
        "Switch to decaf or herbal tea after noon.",
        "Stay hydrated with water throughout the day."
      ],
      "caffeineCutoffTime": "13:00",
      "shouldAvoidCaffeine": true
    },
    "checklistItems": [
      {
        "id": "task_1",
        "action": "Turn off all lights 30 minutes before bed.",
        "isDone": false,
        "priority": "high",
        "durationMinutes": 30
      },
      {
        "id": "task_2",
        "action": "Start your wind-down routine 30 minutes earlier tonight.",
        "isDone": false,
        "priority": "high",
        "durationMinutes": 30
      },
      {
        "id": "task_3",
        "action": "Ensure your bedroom is completely dark and cool for sleep.",
        "isDone": false,
        "priority": "medium",
        "durationMinutes": 0
      },
      {
        "id": "task_4",
        "action": "Avoid screens for 60 minutes before bedtime.",
        "isDone": false,
        "priority": "medium",
        "durationMinutes": 60
      }
    ],
    "sleepWindowSuggestion": {
      "reasoningTitle": "Prioritize sleep recovery.",
      "reasoningDetails": "This earlier window helps maximize sleep duration and reduce accumulated sleep debt.",
      "recommendedBedtime": "22:00",
      "recommendedWakeTime": "06:00"
    }
  },
  "success": true
}