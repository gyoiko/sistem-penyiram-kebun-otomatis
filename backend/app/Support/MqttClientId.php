<?php

namespace App\Support;

use Illuminate\Support\Str;

class MqttClientId
{
    public static function make(): string
    {
        $prefix = (string) config('mqtt.client_id_prefix', 'laravel-kebun');

        return substr($prefix, 0, 10).'-'.Str::lower(Str::random(8));
    }
}
