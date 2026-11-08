<?php

namespace Tests\Feature;

use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TelemetryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_unknown_device_is_registered_automatically_with_default_schedules(): void
    {
        $this->postJson('/api/telemetry', [
            'device_id' => 'esp32-baru',
            'soil_moisture' => 38,
        ])
            ->assertCreated()
            ->assertJson(['success' => true, 'device_id' => 'esp32-baru']);

        $device = Device::findOrFail('esp32-baru');

        $this->assertTrue($device->is_online);
        $this->assertNotNull($device->last_seen_at);
        $this->assertSame(2, $device->schedules()->count());
        $this->assertSame(38, $device->sensorLogs()->firstOrFail()->soil_moisture);
    }

    public function test_telemetry_updates_existing_device(): void
    {
        Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
            'is_online' => false,
        ]);

        $this->postJson('/api/telemetry', [
            'device_id' => 'esp32-depan',
            'soil_moisture' => 72,
        ])->assertCreated();

        $this->assertDatabaseHas('devices', [
            'device_id' => 'esp32-depan',
            'is_online' => 1,
        ]);
        $this->assertDatabaseHas('sensor_logs', [
            'device_id' => 'esp32-depan',
            'soil_moisture' => 72,
        ]);
    }

    public function test_soil_moisture_is_validated(): void
    {
        $this->postJson('/api/telemetry', [
            'device_id' => 'esp32-depan',
            'soil_moisture' => 101,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('soil_moisture');
    }

    public function test_unknown_device_is_ignored_when_auto_register_is_disabled(): void
    {
        config(['mqtt.auto_register' => false]);

        $this->postJson('/api/telemetry', [
            'device_id' => 'esp32-baru',
            'soil_moisture' => 38,
        ])->assertNotFound();

        $this->assertDatabaseMissing('devices', ['device_id' => 'esp32-baru']);
        $this->assertDatabaseMissing('sensor_logs', ['device_id' => 'esp32-baru']);
    }
}
