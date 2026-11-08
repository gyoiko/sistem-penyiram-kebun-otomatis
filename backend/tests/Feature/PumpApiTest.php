<?php

namespace Tests\Feature;

use App\Contracts\MqttPublisher;
use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\FakeMqttPublisher;
use Tests\TestCase;

class PumpApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_manual_trigger_publishes_mqtt_command_and_logs_watering(): void
    {
        $fake = new FakeMqttPublisher;
        $this->app->instance(MqttPublisher::class, $fake);

        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $this->postJson("/api/devices/{$device->device_id}/pump/trigger", [
            'duration_seconds' => 45,
        ])
            ->assertStatus(202)
            ->assertJson([
                'success' => true,
                'duration_seconds' => 45,
            ]);

        $this->assertDatabaseHas('watering_logs', [
            'device_id' => 'esp32-depan',
            'triggered_by' => 'MANUAL_INSTANT',
            'duration_seconds' => 45,
        ]);

        $this->assertCount(1, $fake->messages);

        $message = $fake->messages[0];

        $this->assertSame('kebun/esp32-depan/pompa/command', $message['topic']);
        $this->assertSame('PUMP_ON', $message['payload']['action']);
        $this->assertSame(45, $message['payload']['duration']);
        $this->assertSame('MANUAL_INSTANT', $message['payload']['source']);
        $this->assertArrayHasKey('command_id', $message['payload']);
    }

    public function test_trigger_duration_is_validated(): void
    {
        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $this->postJson("/api/devices/{$device->device_id}/pump/trigger", [
            'duration_seconds' => 1,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('duration_seconds');
    }
}
