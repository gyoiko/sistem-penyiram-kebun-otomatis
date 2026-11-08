# kontrol_iot

Aplikasi Flutter untuk monitoring & penyiraman tanaman otomatis (multi-device ESP32).

## Menjalankan

Backend harus aktif lebih dahulu (lihat `../backend`):

```bash
cd ../backend
php artisan serve            # http://127.0.0.1:8000
php artisan reverb:start     # ws://127.0.0.1:8080
```

Lalu jalankan aplikasi:

```bash
flutter pub get
flutter run -d chrome
```

Default konfigurasi di `lib/core/app_config.dart` mengarah ke `http://127.0.0.1:8000/api`
dan Reverb di `127.0.0.1:8080`. Untuk emulator Android gunakan host `10.0.2.2`:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api \
  --dart-define=REVERB_HOST=10.0.2.2
```

## Struktur

- `lib/data/iot_repository.dart` — REST (`dio`) + Realtime (`dart_pusher_channels`, protokol Pusher/Reverb)
- `lib/state/iot_controller.dart` — `AsyncNotifier` Riverpod, cache state, countdown pompa
- `lib/screens/` — Dashboard, Device Detail, Schedule
- `lib/widgets/` — komponen visual
- `test/` — smoke test dengan `FakeIotRepository`

## Test

```bash
flutter analyze
flutter test
```
