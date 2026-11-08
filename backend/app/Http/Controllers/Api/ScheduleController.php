<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreScheduleRequest;
use App\Http\Requests\UpdateScheduleRequest;
use App\Http\Resources\WateringScheduleResource;
use App\Models\Device;
use App\Models\WateringSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ScheduleController extends Controller
{
    public function index(Device $device): AnonymousResourceCollection
    {
        return WateringScheduleResource::collection(
            $device->schedules()->orderBy('watering_time')->get(),
        );
    }

    public function store(StoreScheduleRequest $request, Device $device): JsonResponse
    {
        $schedule = $device->schedules()->create([
            'watering_time' => $request->validated('watering_time'),
            'duration_seconds' => $request->integer('duration_seconds', 60),
            'is_custom' => true,
            'is_active' => true,
        ]);

        return (new WateringScheduleResource($schedule))
            ->response()
            ->setStatusCode(201);
    }

    public function update(
        UpdateScheduleRequest $request,
        WateringSchedule $schedule,
    ): WateringScheduleResource {
        $schedule->update($request->validated());

        return new WateringScheduleResource($schedule->refresh());
    }

    public function destroy(WateringSchedule $schedule): JsonResponse
    {
        if (! $schedule->is_custom) {
            return response()->json([
                'message' => 'Jadwal default tidak dapat dihapus. Nonaktifkan saja.',
            ], 422);
        }

        $schedule->delete();

        return response()->json(['success' => true]);
    }
}
