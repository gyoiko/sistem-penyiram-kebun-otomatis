<?php

use Illuminate\Support\Facades\Schedule;

Schedule::command('watering:run-due')
    ->everyMinute()
    ->withoutOverlapping()
    ->timezone('Asia/Jakarta')
    ->description('Trigger due watering schedules');
