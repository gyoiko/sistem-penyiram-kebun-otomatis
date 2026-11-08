# Product Requirement Document (PRD)
## Sistem Monitoring & Penyiraman Tanaman Otomatis (Multi-Device IoT)

---

## 1. Executive Summary & Objective

Dokumen ini mendefinisikan spesifikasi sistem untuk pengembangan aplikasi **Frontend (Flutter)** dan **Backend (Laravel / PHP 8.3)**. Sistem dirancang untuk mengelola satu atau banyak perangkat IoT (ESP32) secara *real-time* jarak jauh, dengan fokus utama pada:
* Monitoring status koneksi perangkat secara terpusat (tanpa sensor kelembapan/suhu).
* Penjadwalan penyiraman otomatis harian (**Default: 06:00 & 18:00 WIB**) serta opsi jadwal kustom.
* Fitur penyiraman manual instan (**One-Tap Action**) langsung dari aplikasi.

---

## 2. System Architecture Overview

```text
[ ESP32 Node 1..N ] ──(MQTT/1883)──► [ Broker MQTT: EMQX / Mosquitto ]
                                          │                  ▲
                        (subscribe)       │                  │ (publish PUMP_ON)
                                          ▼                  │
             [ Laravel Worker: artisan mqtt:subscribe ]       │
                          │                                   │
                          ├──► [ SQLite / MySQL (WAL) ]       │
                          └──► [ Laravel Reverb (WebSocket) ]  │
                                          ▲                   │
[ Flutter App ] ◄──(REST + WebSocket Reverb)──► [ Laravel API (php-fpm) + Scheduler ]
                                          │
                                          └──(publish perintah)──┘
```

---

## 3. Backend Specification (Laravel)

### 3.1 Tech Stack & Dependencies
* **Runtime & Framework**: PHP 8.3 dengan Laravel 13.
* **Database Engine**: SQLite (mode **Write-Ahead Logging / WAL** aktif) untuk MVP; jalur produksi MySQL/PostgreSQL.
* **ORM & Migrasi**: Eloquent ORM + Laravel Migrations.
* **MQTT Client Service**: `php-mqtt/client` di dalam Artisan command long-running `mqtt:subscribe` (dijalankan via Supervisor). Reconnect ditangani manual di dalam loop command.
* **Real-time Server**: **Laravel Reverb** (WebSocket, protokol Pusher) + Laravel Events/Broadcasting.
* **Task Scheduler**: Laravel Scheduler (`Schedule::everyMinute()` dengan zona waktu `Asia/Jakarta`), dipicu cron `* * * * *`.
* **Queue**: Laravel Queue (driver `database` untuk MVP, Redis untuk produksi) untuk pemrosesan telemetri dan pengiriman perintah.
* **API Auth (produksi)**: Laravel Sanctum (token per aplikasi).

---

### 3.2 Database Schema (SQLite)

Skema di bawah adalah referensi; implementasi Laravel memakai migration dengan nama kolom yang sama.

```sql
-- Enable Write-Ahead Logging for high concurrency
PRAGMA journal_mode=WAL;
-- SQLite tidak menegakkan foreign key secara default
PRAGMA foreign_keys=ON;

-- Tabel Perangkat ESP32
CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT,
    is_online INTEGER DEFAULT 0,
    led_on INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Jadwal Penyiraman (Default & Kustom)
CREATE TABLE IF NOT EXISTS schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    watering_time TEXT NOT NULL, -- Format "HH:mm" (24 Jam, contoh: "06:00", "18:00")
    duration_seconds INTEGER DEFAULT 60,
    is_custom INTEGER DEFAULT 0, -- 0 = Default System, 1 = Custom User
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Tabel Log Telemetri Sensor
CREATE TABLE IF NOT EXISTS sensor_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    soil_moisture INTEGER NOT NULL,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Tabel Log Riwayat Penyiraman
CREATE TABLE IF NOT EXISTS watering_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    triggered_by TEXT NOT NULL, -- 'SCHEDULE_AUTO' atau 'MANUAL_INSTANT'
    duration_seconds INTEGER NOT NULL,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);
```

---

### 3.3 Core Logic & Workflow

#### A. Registrasi Device Baru & Seed Schedule Default
Saat perangkat ESP32 baru terdeteksi atau didaftarkan (`DeviceController@store`):
1. Backend memasukkan `device_id` ke tabel `devices`.
2. Dalam satu transaksi database, backend membuat **2 jadwal default** di tabel `schedules`:
   * Jam `06:00` WIB (Durasi 60 detik)
   * Jam `18:00` WIB (Durasi 60 detik)

Auto-registrasi dari telemetri MQTT dapat dimatikan dengan `MQTT_AUTO_REGISTER=false` sehingga device wajib didaftarkan lewat aplikasi terlebih dahulu.

#### B. Execution Task Scheduler (Laravel Scheduler)
1. Dijadwalkan setiap menit (`Schedule::everyMinute()->withoutOverlapping()->timezone('Asia/Jakarta')`) dan dipicu cron `* * * * *`.
2. Mengecek waktu server saat ini (misal `06:00`).
3. Mencari semua jadwal di database yang cocok dengan waktu tersebut dan bernilai `is_active = 1`.
4. Menyimpan baris `watering_logs` (`triggered_by: 'SCHEDULE_AUTO'`), lalu mengirimkan pesan MQTT ke topik `kebun/{device_id}/pompa/command`:
   ```json
   {
     "action": "PUMP_ON",
     "duration": 60,
     "source": "SCHEDULE_AUTO"
   }
   ```

#### C. Manual Instant Trigger Flow
1. User menekan tombol **"SIRAM SEKARANG"** di Flutter.
2. Flutter memanggil REST API `POST /api/devices/{id}/pump/trigger`. Kanal WebSocket Reverb hanya untuk server → client, sehingga aksi dari aplikasi selalu lewat REST.
3. Backend memublikasikan ke MQTT `kebun/{device_id}/pompa/command`:
   ```json
   {
     "action": "PUMP_ON",
     "duration": 60,
     "source": "MANUAL_INSTANT"
   }
   ```
4. Backend menyimpan aktivitas ke tabel `watering_logs` (`triggered_by: 'MANUAL_INSTANT'`).

#### D. Kontrol Lampu Internal (Substitusi Pompa)
Selama pompa air belum tersedia, tombol kontrol instan di aplikasi mengendalikan **LED internal ESP32 (GPIO2)**:
1. User menekan tombol **"Nyalakan Lampu" / "Matikan Lampu"**.
2. Flutter memanggil `PUT /api/devices/{id}/lamp` dengan `{ "on": true | false }`.
3. Backend memublikasikan ke `kebun/{device_id}/lampu/command`:
   ```json
   {
     "command_id": "...",
     "action": "LED_ON",
     "issued_at": "..."
   }
   ```
4. ESP32 mengubah GPIO2 lalu mengirim state ke `kebun/{device_id}/lampu/state`:
   ```json
   { "on": true, "state": "ON" }
   ```
5. `mqtt:subscribe` menerima state, menyimpan `devices.led_on`, dan mem-broadcast `.lamp_status`.

---

### 3.4 REST API & WebSocket API Specifications

#### REST Endpoints

| Method | Endpoint | Deskripsi | Payload / Response |
| --- | --- | --- | --- |
| `GET` | `/api/devices` | Mengambil daftar seluruh perangkat ESP32 | `[ { "device_id": "esp32-depan", "name": "Teras Depan", "is_online": 1 } ]` |
| `POST` | `/api/devices` | Registrasi perangkat baru + seed jadwal default | `{ "device_id": "esp32-depan", "name": "Teras Depan" }` |
| `GET` | `/api/devices/:id/schedules` | Mengambil daftar jadwal per perangkat | `[ { "id": 1, "watering_time": "06:00", "is_custom": 0, "is_active": 1 } ]` |
| `POST` | `/api/devices/:id/schedules` | Menambah jadwal penyiraman kustom | `{ "watering_time": "12:00", "duration_seconds": 45 }` |
| `PUT` | `/api/schedules/:id` | Mengubah/Toggle status jadwal | `{ "is_active": 0 }` atau `{ "watering_time": "06:30" }` |
| `DELETE` | `/api/schedules/:id` | Menghapus jadwal (hanya untuk jadwal kustom) | `{ "success": true }` |
| `POST` | `/api/devices/:id/pump/trigger` | Trigger penyiraman manual instan (fallback API) | `{ "duration_seconds": 60 }` |
| `PUT` | `/api/devices/:id/lamp` | Menyalakan/mematikan LED internal ESP32 | `{ "on": true }` |
| `GET` | `/api/devices/:id/sensor-logs?hours=24` | Histori telemetri (opsional, tidak dipakai UI) | `[ { "soil_moisture": 45, "recorded_at": "..." } ]` |
| `POST` | `/api/telemetry` | Ingest telemetri via HTTP (opsional, tidak dipakai firmware) | `{ "device_id": "esp32-depan", "soil_moisture": 45 }` |

#### WebSocket Events (Laravel Reverb / Protokol Pusher)

Kanal: `devices.{device_id}` (public pada MVP tanpa login; ubah menjadi `private-devices.{device_id}` + otorisasi `/broadcasting/auth` setelah Sanctum diaktifkan). Reverb hanya mengirim server → client; semua aksi dari aplikasi melalui REST. Event dibroadcast segera (`ShouldBroadcastNow`) agar latensi trigger tetap rendah — queue worker tidak wajib untuk realtime.

* **Broadcast (Backend → Flutter App)**:
  * `.device_status`: `{ "device_id": "esp32-depan", "is_online": true }`
  * `.pump_status`: `{ "device_id": "esp32-depan", "status": "ON", "source": "MANUAL_INSTANT", "remaining_seconds": 45 }` (opsional, untuk pompa di masa depan)
  * `.lamp_status`: `{ "device_id": "esp32-lampu", "on": true, "state": "ON" }`
* **Client → Backend**: tidak melalui WebSocket. Gunakan REST `PUT /api/devices/{id}/lamp` (dan `POST /api/devices/{id}/pump/trigger` bila pompa tersedia).

---

## 4. Frontend Specification (Flutter)

### 4.1 Tech Stack & State Management
* **Framework**: Flutter (Dart 3.x).
* **State Management**: `flutter_riverpod` (mengelola state per-device secara dinamis dan reaktif).
* **Networking**: `dio` (REST Client) & `dart_pusher_channels` (WebSocket client untuk Laravel Reverb).

---

### 4.2 Layout & Screen UX Specifications

#### Screen 1: Dashboard Multi-Device (Home Screen)
* **Header**: Ringkasan jadwal penyiraman berikutnya (jam + perangkat), status online, dan Tombol (+) Tambah Perangkat Baru.
* **Device Cards Grid**:
  * Badge **Online / Offline** (real-time indikator status koneksi).
  * Jumlah jadwal aktif dan jadwal terdekat (Contoh: *"Berikutnya 18:00 WIB"*).
  * Status lampu (menyala/mati).
  * **Quick Lamp Toggle**: Tombol **"Nyalakan Lampu" / "Matikan Lampu"** langsung dari Card tanpa membuka detail.

#### Screen 2: Device Detail & Control Center
* **Lampu Internal Section**: Tombol besar **"NYALAKAN LAMPU" / "MATIKAN LAMPU"** beserta indikator status ON/OFF (LED bawaan board, GPIO2).
* **Schedule Summary Section**: Daftar chip jadwal aktif (06:00, 18:00, kustom), info jadwal berikutnya, dan tombol **Kelola** menuju layar jadwal.
* **Device Status Section**: Status koneksi, terakhir terlihat, Device ID, dan status lampu.

#### Screen 3: Schedule Management Screen
* **Default Schedule Section**: Cards jadwal default (`06:00 WIB` dan `18:00 WIB`) dilengkapi toggle switch (ON/OFF) serta opsi pengubahan durasi penyiraman.
* **Custom Schedule Section**: Daftar jadwal kustom tambahan yang dibuat pengguna.
* **Floating Action Button (+)**: Membuka modal TimePicker untuk menambahkan jam penyiraman kustom baru.

> Catatan implementasi: selama pompa air belum tersedia, tombol aksi instan pada kartu dan detail perangkat mengendalikan **LED internal ESP32 (GPIO2)** melalui topik `lampu/*` (lihat §3.3-D), bukan pompa.

---

## 5. Non-Functional Requirements (NFR) & Edge Cases

1. **Latensi Trigger Instan**: Waktu dari saat pengguna menekan tombol **"SIRAM SEKARANG"** di Flutter hingga relay ESP32 aktif harus $\le 500\text{ ms}$.
2. **Safety Timeout di ESP32 (Hardware Level)**: Setiap perintah menyala manual selalu disertai argumen durasi. ESP32 secara mandiri wajib mematikan relay menggunakan timer internal (`millis()`), sehingga jika jaringan internet terputus saat penyiraman sedang berlangsung, pompa akan mati otomatis sesuai batas durasi tanpa air meluber.
3. **Konflik Manual vs Jadwal Otomatis**: Jika pengguna menekan penyiraman manual berdekatan dengan jadwal otomatis (misal jam 05:59 WIB), ESP32 akan mengeksekusi durasi terlama tanpa mematikan relay di tengah jalan.
4. **SQLite Concurrency**: Database menggunakan mode `PRAGMA journal_mode=WAL;` dan `PRAGMA foreign_keys=ON;`. SQLite tetap **single-writer** — hanya satu proses yang menulis pada satu waktu. Ini cukup untuk MVP dengan satu queue worker; jika jumlah device bertambah, migrasi ke MySQL/PostgreSQL.
5. **Supervisi Proses**: `mqtt:subscribe`, `queue:work`, dan `reverb:start` wajib dijalankan oleh Supervisor (atau systemd) agar restart otomatis; `schedule:run` dipicu cron setiap menit.
6. **Idempotensi Perintah**: Setiap perintah MQTT menyertakan `command_id` unik agar ESP32 dapat mengabaikan perintah duplikat saat retry.

---

## 6. Deployment & Operations (Laravel)

1. **Proses yang berjalan**: Nginx + `php-fpm` (REST), `php artisan mqtt:subscribe` (Supervisor), `php artisan queue:work` (Supervisor), `php artisan reverb:start` (Supervisor), dan cron `* * * * * php artisan schedule:run`.
2. **Konfigurasi**: kredensial MQTT, `DB_*`, dan `REVERB_*` disimpan di `.env` (tidak di-commit).
3. **Setup awal**: `composer install`, `cp .env.example .env`, `php artisan key:generate`, `php artisan migrate --seed`.
4. **Observability**: Laravel log + Telescope (dev); Horizon (produksi, butuh Redis) untuk memantau queue.
5. **Batas MVP**: SQLite memadai untuk ±100 device dan ±50 pesan/detik. Di atas itu: MySQL/PostgreSQL + queue Redis + broker-side ingestion (rule engine EMQX).