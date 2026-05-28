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
| `geminiResponse`| object | FUNGSI | Balasan JSON dari Gemini |
| `calendarContextDate` | string | FUNGSI | Tanggal konteks (YYYY-MM-DD) |

**Contoh:**
```json
{
  "userId": "usr_abc123",
  "triggeredAt": "2023-10-26T00:00:00Z",
  "inputSnapshot": {"energy": 2, "sleepDebt": 120},
  "geminiResponse": {"checklistItems": []},
  "calendarContextDate": "2023-10-26"
}
```

## Kebutuhan Indeks (Index Requirements)

Indeks gabungan (Composite Indexes) berikut ini diwajibkan (karena dibutuhkan oleh query `date-range`):

- **`sleepLogs`**: `userId` (Naik/ASC), `date` (Turun/DESC)
- **`dailyCheckins`**: `userId` (Naik/ASC), `date` (Turun/DESC)
