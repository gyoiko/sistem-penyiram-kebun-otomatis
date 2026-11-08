<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Device extends Model
{
    protected $primaryKey = 'device_id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'device_id',
        'name',
        'location',
        'is_online',
        'led_on',
        'last_seen_at',
    ];

    protected function casts(): array
    {
        return [
            'is_online' => 'boolean',
            'led_on' => 'boolean',
            'last_seen_at' => 'datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'device_id';
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(WateringSchedule::class, 'device_id', 'device_id');
    }

    public function sensorLogs(): HasMany
    {
        return $this->hasMany(SensorLog::class, 'device_id', 'device_id');
    }

    public function latestSensorLog(): HasOne
    {
        return $this->hasOne(SensorLog::class, 'device_id', 'device_id')
            ->latestOfMany('recorded_at');
    }

    public function wateringLogs(): HasMany
    {
        return $this->hasMany(WateringLog::class, 'device_id', 'device_id');
    }

    public function latestWateringLog(): HasOne
    {
        return $this->hasOne(WateringLog::class, 'device_id', 'device_id')
            ->latestOfMany('executed_at');
    }

    public function seedDefaultSchedules(): void
    {
        if ($this->schedules()->exists()) {
            return;
        }

        foreach (['06:00', '18:00'] as $time) {
            $this->schedules()->create([
                'watering_time' => $time,
                'duration_seconds' => 60,
                'is_custom' => false,
                'is_active' => true,
            ]);
        }
    }
}
