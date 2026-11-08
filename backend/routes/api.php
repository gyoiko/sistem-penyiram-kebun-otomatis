<?php

use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\LampController;
use App\Http\Controllers\Api\PumpController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\SensorLogController;
use App\Http\Controllers\Api\TelemetryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/devices', [DeviceController::class, 'index']);
Route::post('/devices', [DeviceController::class, 'store']);
Route::get('/devices/{device}', [DeviceController::class, 'show']);

Route::get('/devices/{device}/schedules', [ScheduleController::class, 'index']);
Route::post('/devices/{device}/schedules', [ScheduleController::class, 'store']);

Route::get('/devices/{device}/sensor-logs', [SensorLogController::class, 'index']);
Route::post('/devices/{device}/pump/trigger', [PumpController::class, 'store']);
Route::put('/devices/{device}/lamp', [LampController::class, 'update']);

Route::put('/schedules/{schedule}', [ScheduleController::class, 'update']);
Route::patch('/schedules/{schedule}', [ScheduleController::class, 'update']);
Route::delete('/schedules/{schedule}', [ScheduleController::class, 'destroy']);

Route::post('/telemetry', [TelemetryController::class, 'store']);
