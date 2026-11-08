<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SensorLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'soil_moisture' => $this->soil_moisture,
            'recorded_at' => $this->recorded_at->toIso8601String(),
        ];
    }
}
