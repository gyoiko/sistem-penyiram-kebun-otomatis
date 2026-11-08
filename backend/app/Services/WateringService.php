<?php

namespace App\Services;

use App\Contracts\MqttPublisher;
use App\Enums\WateringTrigger;
use App\Models\Device;
use App\Models\WateringLog;
use App\Models\WateringSchedule;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class WateringService
{
    public function __construct(
        private readonly MqttPublisher $mqtt,
        private readonly Realtime $realtime,
    ) {}

    public function trigger(
        Device $device,
        int $durationSeconds,
        WateringTrigger $source,
    ): WateringLog {
        $commandId = (string) Str::uuid();

        $this->mqtt->publish(
            $this->commandTopic($device->device_id),
            [
                'command_id' => $commandId,
                'action' => 'PUMP_ON',
                'duration' => $durationSeconds,
                'source' => $source->value,
                'issued_at' => now()->toIso8601String(),
            ],
        );

        $log = $device->wateringLogs()->create([
            'triggered_by' => $source,
            'duration_seconds' => $durationSeconds,
            'executed_at' => now(),
        ]);

        $this->realtime->pumpStatus(
            $device->device_id,
            'ON',
            $source,
            $durationSeconds,
        );

        return $log;
    }

    public function runDueSchedules(?Carbon $now = null): int
    {
        $now ??= now();
        $time = $now->format('H:i');

        $triggered = 0;

        WateringSchedule::query()
            ->active()
            ->dueAt($time)
            ->with('device')
            ->get()
            ->each(function (WateringSchedule $schedule) use (&$triggered): void {
                if ($schedule->device === null) {
                    return;
                }

                try {
                    $this->trigger(
                        $schedule->device,
                        $schedule->duration_seconds,
                        WateringTrigger::ScheduleAuto,
                    );
                    $triggered++;
                } catch (Throwable $exception) {
                    Log::error('Scheduled watering failed', [
                        'schedule_id' => $schedule->id,
                        'device_id' => $schedule->device_id,
                        'message' => $exception->getMessage(),
                    ]);
                }
            });

        return $triggered;
    }

    private function commandTopic(string $deviceId): string
    {
        return sprintf('%s/%s/pompa/command', config('mqtt.topic_prefix'), $deviceId);
    }
}
