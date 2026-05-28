# OpenCode Handoff

Tanggal: 2026-05-27

## Scope yang dikerjakan

- Hanya menyentuh `frontend/`
- Tidak mengubah backend sama sekali
- Fokus pada:
  - setup Firebase native frontend
  - `Rescue Mode`
  - `Caffeine Advisor`
  - pindah flow sync calendar ke `Schedule`
  - validasi project di laptop ini

## Perubahan yang sudah dibuat

### Firebase native config

Ditambahkan:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Wiring iOS ditambahkan ke:

- `ios/Runner.xcodeproj/project.pbxproj`

### Shared AI harian

Ditambahkan:

- `lib/features/rescue_mode/models/daily_ai_snapshot.dart`
- `lib/features/rescue_mode/repositories/daily_ai_repository.dart`

Tujuan:

- membaca hasil AI harian dari `rescueSessions`
- dipakai bersama oleh `Rescue Mode` dan `Caffeine Advisor`

### Rescue Mode

Diubah:

- `lib/features/rescue_mode/repositories/rescue_repository.dart`

Behavior sekarang:

- `Rescue Mode` tetap satu-satunya flow yang boleh trigger generate AI harian
- sebelum generate, repo cek `rescueSessions` hari ini lewat `DailyAiRepository`
- jika sudah ada hasil hari ini, pakai hasil itu
- jika tidak ada, baru hit endpoint `rescuePlan`
- jika gagal, fallback ke `MockRescueAdvisorService`

### Caffeine Advisor

Diubah penuh:

- `lib/views/caffeine_advisor/caffeine_advisor_page.dart`

Behavior sekarang:

- tidak memicu generate AI baru
- baca `rescueSessions` hari ini jika tersedia
- derive data dari hasil AI `rescuePlan`
  - `caffeineAdvice`
  - `sleepWindowSuggestion`
  - hint nap dari checklist
- kalau belum ada AI hari itu, fallback ke local personalized guidance
- ada label UI kecil yang menjelaskan apakah source-nya AI harian atau fallback lokal

### Calendar sync pindah ke Schedule

Ditambahkan:

- `lib/services/calendar_sync_service.dart`

Diubah:

- `lib/features/schedule/schedule_page.dart`
- `lib/settings_page.dart`

Behavior sekarang:

- tombol connect/resync Google Calendar ada di `Schedule`
- `Settings` hanya menampilkan status/info calendar
- flow OAuth/silent sync dipindahkan ke service khusus agar tidak duplikatif

### Test

Diubah:

- `test/widget_test.dart`

Perubahan:

- test counter bawaan Flutter dihapus
- diganti smoke test `OnboardingPage` yang sesuai app sekarang

## File yang berubah

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `lib/features/rescue_mode/models/daily_ai_snapshot.dart`
- `lib/features/rescue_mode/repositories/daily_ai_repository.dart`
- `lib/features/rescue_mode/repositories/rescue_repository.dart`
- `lib/views/caffeine_advisor/caffeine_advisor_page.dart`
- `lib/services/calendar_sync_service.dart`
- `lib/features/schedule/schedule_page.dart`
- `lib/settings_page.dart`
- `test/widget_test.dart`

## Verifikasi yang sudah dilakukan

Toolchain lokal:

- Flutter di-upgrade ke `3.44.0`
- Dart di-upgrade ke `3.12.0`

Command yang sudah lolos:

- `flutter pub get`
- `flutter test`

Catatan analyzer:

- sebelumnya hanya muncul info/warning lama di repo, bukan compile error dari perubahan ini

## Constraint produk yang dipegang

- backend tidak boleh disentuh
- `Caffeine Advisor` tidak boleh memicu generate baru
- generate AI harian sangat terbatas
- `Rescue Mode` adalah trigger AI utama
- `Caffeine Advisor` hanya membaca hasil AI yang sudah ada atau fallback lokal

## Blocker terakhir

Run Android gagal bukan karena kode, tapi karena storage laptop penuh.

Error terakhir:

- `No space left on device`
- gagal membuat file di `.dart_tool/flutter_build/.../.filecache`

Ruang disk saat dicek:

- hanya tersisa sekitar `188MiB`
- setelah `flutter clean` dan hapus artifact lokal project, naik jadi sekitar `340MiB`
- itu masih belum cukup untuk build Android

## Cleanup yang sudah dilakukan

Sudah dibersihkan dengan aman:

- `frontend/.dart_tool`
- `frontend/build`
- `flutter clean`

Tidak ada source code yang dihapus.

## Next step setelah laptop nyala lagi

1. Kosongkan storage laptop beberapa GB dulu
2. Cek ruang kosong:
   - `df -h`
3. Dari folder `frontend/`, jalankan:
   - `flutter pub get`
   - `flutter run -d emulator-5554`

Kalau mau cari folder besar dulu, pakai:

- `du -sh ~/Downloads/* 2>/dev/null | sort -h`
- `du -sh ~/.gradle 2>/dev/null`
- `du -sh ~/Library/Android/sdk 2>/dev/null`

## Cara lanjut setelah restart

Di sesi OpenCode baru, bilang:

- `lanjut dari frontend/WORKLOG_opencode.md`

Atau minta saya baca file ini dulu sebelum lanjut kerja.
