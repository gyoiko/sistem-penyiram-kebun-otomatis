<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LampStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly string $deviceId,
        public readonly bool $on,
    ) {}

    public function broadcastOn(): Channel
    {
        return new Channel('devices.'.$this->deviceId);
    }

    public function broadcastAs(): string
    {
        return 'lamp_status';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'device_id' => $this->deviceId,
            'on' => $this->on,
            'state' => $this->on ? 'ON' : 'OFF',
        ];
    }
}
