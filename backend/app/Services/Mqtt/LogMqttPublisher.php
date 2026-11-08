<?php

namespace App\Services\Mqtt;

use App\Contracts\MqttPublisher;
use Illuminate\Support\Facades\Log;

class LogMqttPublisher implements MqttPublisher
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function publish(string $topic, array $payload): void
    {
        Log::info('MQTT publish (broker disabled)', [
            'topic' => $topic,
            'payload' => $payload,
        ]);
    }
}
