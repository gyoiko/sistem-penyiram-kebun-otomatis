<?php

namespace App\Models;

use App\Enums\WateringTrigger;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WateringLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'device_id',
        'triggered_by',
        'duration_seconds',
        'executed_at',
    ];

    protected function casts(): array
    {
        return [
            'triggered_by' => WateringTrigger::class,
            'duration_seconds' => 'integer',
            'executed_at' => 'datetime',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }
}
