# Firmware ESP32 — Kontrol Lampu Internal

Project PlatformIO: `firmware/esp32_lampu/` (source: `src/esp32_lampu.ino`).

## Perangkat & library
- Board ESP32 DevKit (LED built-in umumnya di **GPIO2**).
- PlatformIO sudah dikonfigurasi di `platformio.ini` (`esp32dev`, library `knolleary/PubSubClient`).

## 1. Jalankan broker MQTT
Broker ringan tanpa instalasi (butuh Node.js):

```bash
npx -y aedes-cli start --host 0.0.0.0 --port 1883
```

`--host 0.0.0.0` wajib agar ESP32 di jaringan lokal bisa terhubung.
Izinkan juga inbound TCP **1883** di Windows Firewall (butuh admin):

```powershell
New-NetFirewallRule -DisplayName "MQTT 1883" -Direction Inbound -Protocol TCP -LocalPort 1883 -Action Allow
```

## 2. Build & upload

```bash
cd firmware/esp32_lampu
pio run -t upload
pio device monitor
```

Konfigurasi di bagian atas `src/esp32_lampu.ino`:

| Konstanta | Nilai |
| --- | --- |
| `WIFI_SSID` / `WIFI_PASSWORD` | WiFi yang sama dengan komputer |
| `MQTT_HOST` | IP LAN komputer (mis. `192.168.18.195`), **bukan** `127.0.0.1` |
| `DEVICE_ID` | Harus sama dengan Device ID di aplikasi, mis. `esp32-lampu` |
| `LED_PIN` | `2` untuk LED built-in |
| `LED_ACTIVE_HIGH` | `false` jika LED board aktif-low |

## 3. Jalankan backend
Di `backend/.env`:

```env
MQTT_ENABLED=true
MQTT_HOST=127.0.0.1
MQTT_PORT=1883
```

Lalu:

```bash
php artisan mqtt:subscribe     # menerima status + state lampu
php artisan serve
php artisan reverb:start
```

## 4. Kontrol dari aplikasi
1. Tambahkan perangkat di app dengan **Device ID** yang sama (`esp32-lampu`).
2. Tombol **"Nyalakan Lampu" / "Matikan Lampu"** akan mengirim perintah MQTT
   `kebun/esp32-lampu/lampu/command` (`LED_ON` / `LED_OFF`).
3. ESP32 mengubah GPIO2 dan mengirim balik state ke
   `kebun/esp32-lampu/lampu/state`; aplikasi ikut ter-update real-time.

## Topik MQTT

| Arah | Topik | Payload |
| --- | --- | --- |
| App → ESP32 | `kebun/{device_id}/lampu/command` | `{ "action": "LED_ON", "command_id": "...", "issued_at": "..." }` |
| ESP32 → App | `kebun/{device_id}/lampu/state` | `{ "on": true, "state": "ON" }` |
| ESP32 → App | `kebun/{device_id}/status` | `{ "online": true }` + LWT `{ "online": false }` |

Firmware ini tidak membaca sensor kelembapan/suhu.
