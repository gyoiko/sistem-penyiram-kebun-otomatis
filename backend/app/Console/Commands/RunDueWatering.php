<?php

namespace App\Console\Commands;

use App\Services\WateringService;
use Illuminate\Console\Command;

class RunDueWatering extends Command
{
    protected $signature = 'watering:run-due';

    protected $description = 'Trigger watering schedules that match the current minute';

    public function handle(WateringService $watering): int
    {
        $count = $watering->runDueSchedules();

        $this->info("Triggered {$count} schedule(s).");

        return self::SUCCESS;
    }
}
