<?php

namespace App\Services;

use App\Contracts\MqttPublisher;
use App\Models\Device;
use Illuminate\Support\Str;

class LampService
{
    public function __construct(
        private readonly MqttPublisher $mqtt,
        private readonly Realtime $realtime,
    ) {}

    public function setState(Device $device, bool $on): void
    {
        $this->mqtt->publish(
            $this->commandTopic($device->device_id),
            [
                'command_id' => (string) Str::uuid(),
                'action' => $on ? 'LED_ON' : 'LED_OFF',
                'issued_at' => now()->toIso8601String(),
            ],
        );

        $device->update(['led_on' => $on]);

        $this->realtime->lampStatus($device->device_id, $on);
    }

    public function applyReportedState(string $deviceId, bool $on): void
    {
        $device = Device::find($deviceId);

        if ($device === null) {
            return;
        }

        if ($device->led_on !== $on) {
            $device->update(['led_on' => $on]);
        }

        $this->realtime->lampStatus($deviceId, $on);
    }

    private function commandTopic(string $deviceId): string
    {
        return sprintf('%s/%s/lampu/command', config('mqtt.topic_prefix'), $deviceId);
    }
}
