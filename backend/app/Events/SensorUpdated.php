<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class SensorUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly string $deviceId,
        public readonly int $soilMoisture,
        public readonly string $recordedAt,
    ) {}

    public function broadcastOn(): Channel
    {
        return new Channel('devices.'.$this->deviceId);
    }

    public function broadcastAs(): string
    {
        return 'sensor_update';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'device_id' => $this->deviceId,
            'soil_moisture' => $this->soilMoisture,
            'timestamp' => $this->recordedAt,
        ];
    }
}
