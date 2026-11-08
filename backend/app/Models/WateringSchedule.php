<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WateringSchedule extends Model
{
    protected $table = 'schedules';

    protected $fillable = [
        'device_id',
        'watering_time',
        'duration_seconds',
        'is_custom',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'duration_seconds' => 'integer',
            'is_custom' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function scopeDueAt(Builder $query, string $time): Builder
    {
        return $query->where('watering_time', $time);
    }
}
