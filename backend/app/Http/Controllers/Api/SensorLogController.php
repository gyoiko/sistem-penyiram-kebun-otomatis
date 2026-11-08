<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SensorLogResource;
use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SensorLogController extends Controller
{
    public function index(Request $request, Device $device): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'hours' => ['sometimes', 'integer', 'min:1', 'max:168'],
        ]);

        $hours = (int) ($validated['hours'] ?? 24);

        $logs = $device->sensorLogs()
            ->where('recorded_at', '>=', now()->subHours($hours))
            ->orderBy('recorded_at')
            ->get(['soil_moisture', 'recorded_at']);

        return SensorLogResource::collection($logs);
    }
}
