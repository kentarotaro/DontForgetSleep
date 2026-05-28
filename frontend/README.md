# dont_forget_sleep

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API Smoke Check

You can run a quick backend endpoint smoke check from frontend:

```bash
dart run bin/api_smoke.dart --userId "your_uid"
```

Optional flags:

- `--date YYYY-MM-DD` to test a specific date
- `--with-write` to include write endpoints (`scheduleItemCreate`, `goalItemCreate`)

Example:

```bash
dart run bin/api_smoke.dart --userId "your_uid" --date "2026-05-28" --with-write
```
