<?php

namespace App\Services;

use App\Enums\WateringTrigger;
use App\Events\DeviceStatusChanged;
use App\Events\LampStatusChanged;
use App\Events\PumpStatusChanged;
use App\Events\SensorUpdated;
use App\Models\Device;
use App\Models\SensorLog;
use Illuminate\Support\Facades\Log;
use Throwable;

class Realtime
{
    public function sensorUpdated(Device $device, SensorLog $log): void
    {
        $this->send(new SensorUpdated(
            deviceId: $device->device_id,
            soilMoisture: $log->soil_moisture,
            recordedAt: $log->recorded_at->toIso8601String(),
        ));
    }

    public function deviceStatus(Device $device): void
    {
        $this->send(new DeviceStatusChanged(
            deviceId: $device->device_id,
            isOnline: $device->is_online,
            lastSeenAt: $device->last_seen_at?->toIso8601String(),
        ));
    }

    public function pumpStatus(
        string $deviceId,
        string $status,
        WateringTrigger $source,
        int $remainingSeconds,
    ): void {
        $this->send(new PumpStatusChanged(
            deviceId: $deviceId,
            status: $status,
            source: $source->value,
            remainingSeconds: $remainingSeconds,
        ));
    }

    public function lampStatus(string $deviceId, bool $on): void
    {
        $this->send(new LampStatusChanged(
            deviceId: $deviceId,
            on: $on,
        ));
    }

    private function send(object $event): void
    {
        try {
            broadcast($event);
        } catch (Throwable $exception) {
            Log::warning('Broadcast failed', [
                'event' => $event::class,
                'message' => $exception->getMessage(),
            ]);
        }
    }
}
