<?php

namespace App\Services;

use App\Models\Device;
use App\Models\SensorLog;
use Illuminate\Support\Carbon;

class TelemetryService
{
    public function __construct(private readonly Realtime $realtime) {}

    public function ingest(
        string $deviceId,
        int $soilMoisture,
        ?Carbon $recordedAt = null,
    ): ?SensorLog {
        $device = Device::find($deviceId);

        if ($device === null) {
            if (! config('mqtt.auto_register')) {
                return null;
            }

            $device = Device::create([
                'device_id' => $deviceId,
                'name' => $deviceId,
                'is_online' => true,
            ]);

            $device->seedDefaultSchedules();
            $this->realtime->deviceStatus($device);
        }

        $log = $device->sensorLogs()->create([
            'soil_moisture' => $soilMoisture,
            'recorded_at' => $recordedAt ?? now(),
        ]);

        $device->update([
            'is_online' => true,
            'last_seen_at' => now(),
        ]);

        $this->realtime->sensorUpdated($device, $log);

        return $log;
    }

    public function markOnline(string $deviceId): void
    {
        $device = Device::find($deviceId);

        if ($device === null) {
            return;
        }

        $device->update(['is_online' => true, 'last_seen_at' => now()]);
        $this->realtime->deviceStatus($device);
    }

    public function markOffline(string $deviceId): void
    {
        $device = Device::find($deviceId);

        if ($device === null) {
            return;
        }

        $device->update(['is_online' => false]);
        $this->realtime->deviceStatus($device);
    }
}
