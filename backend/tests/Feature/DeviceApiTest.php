<?php

namespace Tests\Feature;

use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_lists_devices_with_latest_moisture(): void
    {
        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
            'location' => 'Blok A',
            'is_online' => true,
        ]);

        $device->sensorLogs()->create([
            'soil_moisture' => 41,
            'recorded_at' => now()->subMinutes(10),
        ]);
        $device->sensorLogs()->create([
            'soil_moisture' => 55,
            'recorded_at' => now(),
        ]);

        $device->wateringLogs()->create([
            'triggered_by' => 'MANUAL_INSTANT',
            'duration_seconds' => 30,
            'executed_at' => now()->subMinutes(5),
        ]);

        $this->getJson('/api/devices')
            ->assertOk()
            ->assertJsonPath('data.0.device_id', 'esp32-depan')
            ->assertJsonPath('data.0.soil_moisture', 55)
            ->assertJsonPath('data.0.is_online', true)
            ->assertJsonPath(
                'data.0.last_watered_at',
                now()->subMinutes(5)->toIso8601String(),
            );
    }

    public function test_it_registers_a_device_with_default_schedules(): void
    {
        $this->postJson('/api/devices', [
            'device_id' => 'esp32-uji',
            'name' => 'Kebun Uji',
            'location' => 'Lab',
        ])
            ->assertCreated()
            ->assertJsonPath('data.device_id', 'esp32-uji')
            ->assertJsonCount(2, 'data.schedules');

        $this->assertDatabaseHas('devices', ['device_id' => 'esp32-uji']);
        $this->assertDatabaseHas('schedules', [
            'device_id' => 'esp32-uji',
            'watering_time' => '06:00',
            'duration_seconds' => 60,
            'is_custom' => 0,
            'is_active' => 1,
        ]);
        $this->assertDatabaseHas('schedules', [
            'device_id' => 'esp32-uji',
            'watering_time' => '18:00',
        ]);
    }

    public function test_device_id_must_be_unique(): void
    {
        Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $this->postJson('/api/devices', [
            'device_id' => 'esp32-depan',
            'name' => 'Duplikat',
        ])->assertUnprocessable()->assertJsonValidationErrors('device_id');
    }

    public function test_it_returns_sensor_history(): void
    {
        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $device->sensorLogs()->create([
            'soil_moisture' => 30,
            'recorded_at' => now()->subHours(30),
        ]);
        $device->sensorLogs()->create([
            'soil_moisture' => 60,
            'recorded_at' => now()->subHour(),
        ]);

        $this->getJson('/api/devices/esp32-depan/sensor-logs?hours=24')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.soil_moisture', 60);
    }
}
