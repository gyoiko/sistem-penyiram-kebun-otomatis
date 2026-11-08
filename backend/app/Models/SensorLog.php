<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SensorLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'device_id',
        'soil_moisture',
        'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'soil_moisture' => 'integer',
            'recorded_at' => 'datetime',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }
}
