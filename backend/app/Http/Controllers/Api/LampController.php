<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateLampRequest;
use App\Models\Device;
use App\Services\LampService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class LampController extends Controller
{
    public function update(
        UpdateLampRequest $request,
        Device $device,
        LampService $lamp,
    ): JsonResponse {
        $on = $request->boolean('on');

        try {
            $lamp->setState($device, $on);
        } catch (Throwable $exception) {
            Log::error('Failed to publish lamp command', [
                'device_id' => $device->device_id,
                'message' => $exception->getMessage(),
            ]);

            return response()->json([
                'message' => 'Perintah lampu gagal dikirim ke broker MQTT.',
            ], 503);
        }

        return response()->json([
            'success' => true,
            'led_on' => $on,
        ], 202);
    }
}
