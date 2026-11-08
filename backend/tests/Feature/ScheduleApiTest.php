<?php

namespace Tests\Feature;

use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ScheduleApiTest extends TestCase
{
    use RefreshDatabase;

    private function deviceWithDefaults(): Device
    {
        $device = Device::create([
            'device_id' => 'esp32-depan',
            'name' => 'Teras Depan',
        ]);

        $device->seedDefaultSchedules();

        return $device;
    }

    public function test_it_creates_a_custom_schedule(): void
    {
        $device = $this->deviceWithDefaults();

        $this->postJson("/api/devices/{$device->device_id}/schedules", [
            'watering_time' => '12:00',
            'duration_seconds' => 45,
        ])
            ->assertCreated()
            ->assertJsonPath('data.watering_time', '12:00')
            ->assertJsonPath('data.duration_seconds', 45)
            ->assertJsonPath('data.is_custom', true);
    }

    public function test_it_validates_schedule_time_and_duration(): void
    {
        $device = $this->deviceWithDefaults();

        $this->postJson("/api/devices/{$device->device_id}/schedules", [
            'watering_time' => '25:00',
            'duration_seconds' => 2,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['watering_time', 'duration_seconds']);
    }

    public function test_it_toggles_and_updates_a_schedule(): void
    {
        $device = $this->deviceWithDefaults();
        $schedule = $device->schedules()->where('watering_time', '06:00')->firstOrFail();

        $this->putJson("/api/schedules/{$schedule->id}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('schedules', ['id' => $schedule->id, 'is_active' => 0]);
    }

    public function test_default_schedule_cannot_be_deleted(): void
    {
        $device = $this->deviceWithDefaults();
        $schedule = $device->schedules()->where('watering_time', '06:00')->firstOrFail();

        $this->deleteJson("/api/schedules/{$schedule->id}")
            ->assertUnprocessable();

        $this->assertDatabaseHas('schedules', ['id' => $schedule->id]);
    }

    public function test_custom_schedule_can_be_deleted(): void
    {
        $device = $this->deviceWithDefaults();
        $schedule = $device->schedules()->create([
            'watering_time' => '12:00',
            'duration_seconds' => 30,
            'is_custom' => true,
            'is_active' => true,
        ]);

        $this->deleteJson("/api/schedules/{$schedule->id}")
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('schedules', ['id' => $schedule->id]);
    }
}
