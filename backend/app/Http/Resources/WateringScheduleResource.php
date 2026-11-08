<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WateringScheduleResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'device_id' => $this->device_id,
            'watering_time' => $this->watering_time,
            'duration_seconds' => $this->duration_seconds,
            'is_custom' => $this->is_custom,
            'is_active' => $this->is_active,
        ];
    }
}
