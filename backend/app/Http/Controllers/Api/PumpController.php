<?php

namespace App\Http\Controllers\Api;

use App\Enums\WateringTrigger;
use App\Http\Controllers\Controller;
use App\Http\Requests\TriggerPumpRequest;
use App\Models\Device;
use App\Services\WateringService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class PumpController extends Controller
{
    public function store(
        TriggerPumpRequest $request,
        Device $device,
        WateringService $watering,
    ): JsonResponse {
        $duration = $request->integer('duration_seconds', 60);

        try {
            $log = $watering->trigger(
                $device,
                $duration,
                WateringTrigger::ManualInstant,
            );
        } catch (Throwable $exception) {
            Log::error('Failed to publish pump command', [
                'device_id' => $device->device_id,
                'message' => $exception->getMessage(),
            ]);

            return response()->json([
                'message' => 'Perintah gagal dikirim ke broker MQTT.',
            ], 503);
        }

        return response()->json([
            'success' => true,
            'watering_log_id' => $log->id,
            'duration_seconds' => $duration,
        ], 202);
    }
}
