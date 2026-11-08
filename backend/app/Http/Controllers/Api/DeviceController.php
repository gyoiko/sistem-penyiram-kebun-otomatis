<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDeviceRequest;
use App\Http\Resources\DeviceResource;
use App\Models\Device;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class DeviceController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $devices = Device::query()
            ->with(['latestSensorLog', 'latestWateringLog'])
            ->orderBy('name')
            ->get();

        return DeviceResource::collection($devices);
    }

    public function store(StoreDeviceRequest $request): JsonResponse
    {
        $device = DB::transaction(function () use ($request): Device {
            $device = Device::create([
                ...$request->validated(),
                'is_online' => false,
            ]);

            $device->seedDefaultSchedules();

            return $device;
        });

        $device->load(['latestSensorLog', 'latestWateringLog', 'schedules']);

        return (new DeviceResource($device))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Device $device): DeviceResource
    {
        $device->load(['latestSensorLog', 'latestWateringLog', 'schedules']);

        return new DeviceResource($device);
    }
}
