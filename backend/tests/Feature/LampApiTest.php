<?php

namespace Tests\Feature;

use App\Contracts\MqttPublisher;
use App\Models\Device;
use App\Services\LampService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\FakeMqttPublisher;
use Tests\TestCase;

class LampApiTest extends TestCase
{
    use RefreshDatabase;

    private function createDevice(): Device
    {
        return Device::create([
            'device_id' => 'esp32-lampu',
            'name' => 'Lampu Uji',
            'is_online' => true,
        ]);
    }

    public function test_it_publishes_led_on_command_and_updates_state(): void
    {
        $fake = new FakeMqttPublisher;
        $this->app->instance(MqttPublisher::class, $fake);

        $device = $this->createDevice();

        $this->putJson("/api/devices/{$device->device_id}/lamp", ['on' => true])
            ->assertStatus(202)
            ->assertJson(['success' => true, 'led_on' => true]);

        $this->assertDatabaseHas('devices', [
            'device_id' => 'esp32-lampu',
            'led_on' => 1,
        ]);

        $this->assertCount(1, $fake->messages);
        $this->assertSame('kebun/esp32-lampu/lampu/command', $fake->messages[0]['topic']);
        $this->assertSame('LED_ON', $fake->messages[0]['payload']['action']);
        $this->assertArrayHasKey('command_id', $fake->messages[0]['payload']);
    }

    public function test_it_publishes_led_off_command(): void
    {
        $fake = new FakeMqttPublisher;
        $this->app->instance(MqttPublisher::class, $fake);

        $device = $this->createDevice();
        $device->update(['led_on' => true]);

        $this->putJson("/api/devices/{$device->device_id}/lamp", ['on' => false])
            ->assertStatus(202)
            ->assertJson(['led_on' => false]);

        $this->assertDatabaseHas('devices', [
            'device_id' => 'esp32-lampu',
            'led_on' => 0,
        ]);
        $this->assertSame('LED_OFF', $fake->messages[0]['payload']['action']);
    }

    public function test_on_is_required_and_boolean(): void
    {
        $device = $this->createDevice();

        $this->putJson("/api/devices/{$device->device_id}/lamp", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('on');
    }

    public function test_reported_state_updates_device(): void
    {
        $device = $this->createDevice();

        app(LampService::class)->applyReportedState($device->device_id, true);

        $this->assertDatabaseHas('devices', [
            'device_id' => 'esp32-lampu',
            'led_on' => 1,
        ]);
    }
}
