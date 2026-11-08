<?php

namespace Tests\Feature;

use App\Contracts\MqttPublisher;
use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Support\FakeMqttPublisher;
use Tests\TestCase;

class ScheduleRunnerTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_triggers_only_active_schedules_matching_current_minute(): void
    {
        $fake = new FakeMqttPublisher;
        $this->app->instance(MqttPublisher::class, $fake);

        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $device->schedules()->create([
            'watering_time' => '06:00',
            'duration_seconds' => 60,
            'is_custom' => false,
            'is_active' => true,
        ]);
        $device->schedules()->create([
            'watering_time' => '06:00',
            'duration_seconds' => 30,
            'is_custom' => false,
            'is_active' => false,
        ]);
        $device->schedules()->create([
            'watering_time' => '18:00',
            'duration_seconds' => 60,
            'is_custom' => false,
            'is_active' => true,
        ]);

        $this->travelTo(Carbon::parse('2026-11-08 06:00:00'));

        $this->artisan('watering:run-due')->assertSuccessful();

        $this->assertDatabaseCount('watering_logs', 1);
        $this->assertDatabaseHas('watering_logs', [
            'device_id' => 'esp32-depan',
            'triggered_by' => 'SCHEDULE_AUTO',
            'duration_seconds' => 60,
        ]);
        $this->assertCount(1, $fake->messages);
        $this->assertSame('SCHEDULE_AUTO', $fake->messages[0]['payload']['source']);
    }

    public function test_it_does_nothing_outside_schedule_minute(): void
    {
        $fake = new FakeMqttPublisher;
        $this->app->instance(MqttPublisher::class, $fake);

        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $device->schedules()->create([
            'watering_time' => '06:00',
            'duration_seconds' => 60,
            'is_custom' => false,
            'is_active' => true,
        ]);

        $this->travelTo(Carbon::parse('2026-11-08 06:01:00'));

        $this->artisan('watering:run-due')->assertSuccessful();

        $this->assertDatabaseCount('watering_logs', 0);
        $this->assertCount(0, $fake->messages);
    }
}
