<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\IngestTelemetryRequest;
use App\Services\TelemetryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class TelemetryController extends Controller
{
    public function store(
        IngestTelemetryRequest $request,
        TelemetryService $telemetry,
    ): JsonResponse {
        $data = $request->validated();

        $log = $telemetry->ingest(
            $data['device_id'],
            (int) $data['soil_moisture'],
            isset($data['recorded_at']) ? Carbon::parse($data['recorded_at']) : null,
        );

        if ($log === null) {
            return response()->json([
                'success' => false,
                'message' => 'Perangkat belum terdaftar.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'device_id' => $log->device_id,
            'recorded_at' => $log->recorded_at->toIso8601String(),
        ], 201);
    }
}
