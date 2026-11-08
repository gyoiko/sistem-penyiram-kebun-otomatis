<?php

namespace App\Enums;

enum WateringTrigger: string
{
    case ScheduleAuto = 'SCHEDULE_AUTO';
    case ManualInstant = 'MANUAL_INSTANT';

    public function label(): string
    {
        return match ($this) {
            self::ScheduleAuto => 'Jadwal otomatis',
            self::ManualInstant => 'Manual instan',
        };
    }
}
