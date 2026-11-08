<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'device_id' => $this->device_id,
            'name' => $this->name,
            'location' => $this->location,
            'is_online' => $this->is_online,
            'led_on' => $this->led_on,
            'soil_moisture' => $this->whenLoaded(
                'latestSensorLog',
                fn () => $this->latestSensorLog?->soil_moisture,
            ),
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
            'last_watered_at' => $this->whenLoaded(
                'latestWateringLog',
                fn () => $this->latestWateringLog?->executed_at?->toIso8601String(),
            ),
            'created_at' => $this->created_at?->toIso8601String(),
            'schedules' => WateringScheduleResource::collection(
                $this->whenLoaded('schedules'),
            ),
        ];
    }
}
