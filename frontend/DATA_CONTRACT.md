# D.F.S (Don't Forget Sleep) — Kontrak Data (Data Contract)
 
Dokumen ini menguraikan kontrak komunikasi antara frontend Flutter dan backend Firebase untuk fase MVP. Arsitektur backend menggunakan Context Injection (Penyuntikan Konteks) tanpa vector embedding.
 
---
 
## Bagian 1: Informasi Deployment
 
### URL Production
 
Setiap Cloud Function memiliki URL tersendiri. Tidak ada base URL tunggal.
 
| Function | URL Production |
|---|---|
| rescuePlan | https://rescueplan-v4gtcfan5q-uc.a.run.app |
| dailyInsight | https://dailyinsight-v4gtcfan5q-uc.a.run.app |
| syncCalendar | https://synccalendar-v4gtcfan5q-uc.a.run.app |
| oauthCallback | https://oauthcallback-v4gtcfan5q-uc.a.run.app |
| sleepHistory | https://sleephistory-v4gtcfan5q-uc.a.run.app |
| scheduleItemCreate | https://scheduleitemcreate-v4gtcfan5q-uc.a.run.app |
| scheduleItemList | https://scheduleitemlist-v4gtcfan5q-uc.a.run.app |
| goalItemCreate | https://goalitemcreate-v4gtcfan5q-uc.a.run.app |
| goalItemList | https://goalitemlist-v4gtcfan5q-uc.a.run.app |
| generateSchedulePlan | https://generatescheduleplan-v4gtcfan5q-uc.a.run.app |
 
### Informasi Proyek Firebase
 
| Parameter | Nilai |
|---|---|
| Project ID | dontforgetsleep-b146c |
| Region | us-central1 |
| Firestore | Cloud Firestore (default database) |
 
---
 
## Bagian 2: Konvensi Umum
 
- **Kunci API**: Semua kunci JSON menggunakan `camelCase`.
- **Format Waktu**: Semua waktu pada respons API menggunakan format ISO 8601 (contoh: `"2026-05-22T22:30:00+07:00"`).
- **Zona Waktu**: WIB (UTC+7) untuk tampilan dan respons, UTC untuk penyimpanan di Firestore.
- **Identitas Pengguna**: Seluruh field `userId` menggunakan Firebase Auth UID, bukan email.
- **Pembungkus Sukses**:
  ```json
  { "success": true, "data": { ... } }
  ```
- **Pembungkus Error**:
  ```json
  { "success": false, "code": "KODE_ERROR", "message": "Pesan error" }
  ```
 
### Daftar Kode Error
 
| Kode | Keterangan |
|---|---|
| `USER_NOT_FOUND` | Pengguna tidak ditemukan di Firestore |
| `MISSING_FIELD` | Ada field wajib yang tidak disertakan pada request |
| `CALENDAR_NOT_CONNECTED` | Pengguna belum menghubungkan Google Calendar |
| `GEMINI_UNAVAILABLE` | Layanan Gemini API tidak dapat diakses |
| `INSUFFICIENT_SLEEP_DATA` | Data tidur kurang dari jumlah minimum yang dibutuhkan |
| `SERVER_ERROR` | Kesalahan internal pada server |
 
---
 
## Bagian 3: Autentikasi
 
Firebase Authentication sudah aktif dengan dua provider berikut.
 
- **Email/Password**: Pengguna mendaftar menggunakan nama depan, nama belakang, email, dan kata sandi. Firebase Auth menyediakan verifikasi email dan reset kata sandi secara bawaan.
- **Google Sign-In**: Login menggunakan akun Google.
Autentikasi ditangani sepenuhnya di sisi klien Flutter menggunakan paket `firebase_auth` dan `google_sign_in`. Backend tidak memproses kredensial secara langsung.
 
Setelah pengguna berhasil mendaftar melalui metode apapun, Flutter wajib segera membuat dokumen `userProfiles/{uid}` di Firestore dengan struktur berikut:
 
```json
{
  "userId": "uid",
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "calendarConnected": false,
  "onboardingCompleted": false,
  "settingsCompleted": false
}
```
 
Backend tidak lagi memiliki trigger otomatis untuk pembuatan profil pengguna. Tanggung jawab pembuatan dokumen ini sepenuhnya ada pada klien Flutter.
 
---
 
## Bagian 4: Akses Langsung Firestore (Flutter SDK)
 
Flutter dapat membaca dan menulis secara langsung ke koleksi berikut menggunakan FlutterFire SDK. Semua koleksi berada di tingkat akar (root level) dan membutuhkan field `userId` yang sesuai dengan UID pengguna yang sedang terautentikasi.
 
| Koleksi | Akses Klien |
|---|---|
| `userProfiles/{uid}` | Baca dan Tulis (kecuali field `calendarConnected`) |
| `sleepLogs` | Buat dan Baca dokumen milik sendiri |
| `dailyCheckins` | Buat dan Baca dokumen milik sendiri |
| `scheduleItems` | Buat dan Baca dokumen milik sendiri |
| `calendarEvents` | Baca saja (dibuat oleh backend melalui syncCalendar) |
| `rescueSessions` | Baca saja (dibuat oleh backend) |
 
---
 
## Bagian 5: Skema Koleksi Firestore
 
### userProfiles/{uid}
 
| Field | Tipe | Penulis | Keterangan |
|---|---|---|---|
| userId | string | KLIEN | Sama dengan Firebase Auth UID |
| firstName | string | KLIEN | Nama depan pengguna |
| lastName | string | KLIEN | Nama belakang pengguna |
| email | string | KLIEN | Email pengguna |
| calendarConnected | boolean | FUNCTION | Hanya dapat diubah oleh backend |
| onboardingCompleted | boolean | KLIEN | Diset true setelah menjawab 3 pertanyaan onboarding |
| settingsCompleted | boolean | KLIEN | Diset true setelah mengatur sleep floor dan wake window |
| morningTirednessFrequency | string | KLIEN | Nilai: always, usually, sometimes, rarely |
| usualSleepDuration | string | KLIEN | Nilai: under6h, 6to8h, 8to10h, over10h |
| sleepHabits | array | KLIEN | Nilai: stayUpLate, sleepWetHair, heavyFoodBeforeSleep, sleepWithLightOn, noneOfThese |
| sleepFloorHours | number | KLIEN | Nilai: 6, 7, atau 8 |
| preferredWakeTime | string | KLIEN | Format HH:MM, contoh: "06:30" |
| preferredBedtime | string | KLIEN | Format HH:MM, contoh: "23:00" |
 
### sleepLogs/{logId}
 
| Field | Tipe | Penulis | Keterangan |
|---|---|---|---|
| userId | string | KLIEN | Firebase Auth UID |
| date | string | KLIEN | Format YYYY-MM-DD |
| bedtime | string | KLIEN | Format ISO 8601 |
| wakeTime | string | KLIEN | Format ISO 8601 |
| durationMinutes | number | KLIEN | Total durasi tidur dalam menit |
| quality | number | KLIEN | Skala 1-5 |
 
### dailyCheckins/{checkinId}
 
| Field | Tipe | Penulis | Keterangan |
|---|---|---|---|
| userId | string | KLIEN | Firebase Auth UID |
| date | string | KLIEN | Format YYYY-MM-DD |
| energyLevel | number | KLIEN | Skala 1-5 |
| caffeineIntakeMg | number | KLIEN | Konsumsi kafein dalam miligram |
| mood | string | KLIEN | Nilai: great, good, neutral, bad, terrible |
| notes | string | KLIEN | Catatan singkat opsional, maks 280 karakter |
| sleepDurationLastNight | number | KLIEN | Nilai: 4, 5, 6, 7, atau 8 (8 berarti lebih dari 8 jam) |
 
---
 
## Bagian 6: Titik Akhir (Endpoints) Cloud Function
 
Seluruh endpoint menerima method POST kecuali dinyatakan lain, dengan header `Content-Type: application/json`.
 
### POST /rescuePlan
 
Menghasilkan rencana pemulihan yang dipersonalisasi. Membutuhkan minimal 3 dokumen `sleepLogs`.
 
**Request Body:**
```json
{
  "userId": "string",
  "currentDate": "YYYY-MM-DD",
  "currentEnergyLevel": 2,
  "currentSleepDebtMinutes": 90
}
```
 
**Response Data:**
```json
{
  "checklistItems": [
    {
      "id": "string",
      "action": "string",
      "durationMinutes": 30,
      "priority": "high"
    }
  ],
  "sleepWindowSuggestion": {
    "recommendedBedtime": "23:00",
    "recommendedWakeTime": "07:00",
    "reasoning": "string"
  },
  "caffeineAdvice": "string"
}
```
 
Nilai `priority`: `high`, `medium`, atau `low`.
 
### POST /dailyInsight
 
Menghasilkan wawasan harian berdasarkan riwayat tidur. Membutuhkan minimal 5 dokumen `sleepLogs`.
 
**Request Body:**
```json
{
  "userId": "string",
  "date": "YYYY-MM-DD"
}
```
 
**Response Data:**
```json
{
  "insightTitle": "string",
  "insightBody": "string",
  "trendTag": "improving",
  "recommendation": "string",
  "dataPointsUsed": 5
}
```
 
Nilai `trendTag`: `improving`, `stable`, atau `declining`.
 
### POST /syncCalendar
 
Memicu sinkronisasi Google Calendar pengguna dan menghitung skor stres per acara. Pengguna harus sudah menyelesaikan alur OAuth Google Calendar terlebih dahulu.
 
**Request Body:**
```json
{
  "userId": "string",
  "dateRange": {
    "start": "YYYY-MM-DD",
    "end": "YYYY-MM-DD"
  }
}
```
 
**Response Data:**
```json
{
  "syncedCount": 4,
  "highStressEvents": [
    {
      "title": "string",
      "date": "YYYY-MM-DD",
      "stressScore": 0.75
    }
  ]
}
```
 
### GET /sleepHistory
 
Mengambil riwayat log tidur beserta ringkasannya.
 
**Query Parameters:**
 
| Parameter | Tipe | Wajib | Keterangan |
|---|---|---|---|
| userId | string | Ya | Firebase Auth UID |
| days | number | Tidak | Default 30, maksimum 90 |
 
**Response Data:**
```json
{
  "logs": [
    {
      "date": "YYYY-MM-DD",
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
 
### POST /scheduleItemCreate
 
Menyimpan satu jadwal harian secara manual, digunakan untuk pengguna yang tidak menghubungkan Google Calendar.
 
**Request Body:**
```json
{
  "userId": "string",
  "title": "string",
  "startTime": "2026-05-22T09:00:00Z",
  "endTime": "2026-05-22T11:00:00Z",
  "date": "YYYY-MM-DD"
}
```
 
**Response Data:**
```json
{
  "itemId": "string"
}
```
 
### GET /scheduleItemList
 
Mengambil seluruh jadwal manual pada tanggal tertentu.
 
**Query Parameters:**
 
| Parameter | Tipe | Wajib |
|---|---|---|
| userId | string | Ya |
| date | string (YYYY-MM-DD) | Ya |
 
**Response Data:**
```json
{
  "items": [
    {
      "itemId": "string",
      "title": "string",
      "startTime": "2026-05-22T09:00:00Z",
      "endTime": "2026-05-22T11:00:00Z",
      "date": "YYYY-MM-DD"
    }
  ]
}
```
 
### POST /generateSchedulePlan
 
Menggunakan AI untuk menyusun jadwal harian pengguna secara otomatis berdasarkan data goals dan sleep window.
 
**Request Body:**
```json
{
  "userId": "string",
  "date": "YYYY-MM-DD"
}
```
 
**Response Data:**
```json
{
  "plannedItems": [
    {
      "itemId": "string",
      "title": "string",
      "startTime": "2026-05-22T14:00:00Z",
      "endTime": "2026-05-22T15:00:00Z"
    }
  ],
  "advice": "string"
}
```
 
---
 
## Bagian 7: Alur Google Calendar OAuth
 
Untuk pengguna yang ingin menghubungkan Google Calendar, Flutter membuka URL berikut di browser:
 
```
https://accounts.google.com/o/oauth2/v2/auth
  ?client_id={GOOGLE_CLIENT_ID}
  &redirect_uri=https://oauthcallback-v4gtcfan5q-uc.a.run.app
  &response_type=code
  &scope=https://www.googleapis.com/auth/calendar.readonly
  &state={userId}
```
 
Setelah pengguna memberikan izin, Google akan mengarahkan ke endpoint `oauthCallback` secara otomatis. Backend akan menyimpan token dan memperbarui field `calendarConnected` menjadi `true` pada dokumen `userProfiles/{uid}`.
 
Flutter cukup memantau field `calendarConnected` di Firestore untuk mengetahui status koneksi kalender pengguna.
 
---
 
## Bagian 8: Alur Onboarding Pengguna
 
1. **Registrasi**: Flutter melakukan sign-up melalui Firebase Auth. Setelah berhasil, Flutter langsung membuat dokumen `userProfiles/{uid}` di Firestore.
2. **Pertanyaan Onboarding**: Flutter memperbarui dokumen `userProfiles` dengan field `morningTirednessFrequency`, `usualSleepDuration`, dan `sleepHabits`. Setelah selesai, set `onboardingCompleted: true`.
3. **Pengaturan Tidur**: Flutter memperbarui `sleepFloorHours`, `preferredWakeTime`, dan `preferredBedtime`. Setelah selesai, set `settingsCompleted: true`.
4. **Aktivitas Harian**: Flutter mengisi dokumen `dailyCheckins` dan `sleepLogs` secara langsung ke Firestore.
5. **Fitur AI**: Flutter memanggil `/rescuePlan`, `/dailyInsight`, atau `/generateSchedulePlan` sesuai kebutuhan.
6. **Kalender (Opsional)**: Flutter memulai alur OAuth Google Calendar. Setelah terhubung, panggil `/syncCalendar` untuk sinkronisasi data.
---
 
## Bagian 9: Yang Tidak Boleh Dikirim oleh Klien
 
- API key Gemini atau kredensial Google Service Account dalam bentuk apapun.
- Field `stressScore` pada `calendarEvents` (hanya dihitung oleh backend).
- Field `inputSnapshot` atau `geminiResponse` pada `rescueSessions`.
- Perubahan langsung pada field `calendarConnected` di `userProfiles` (hanya backend yang boleh memperbarui field ini).
 