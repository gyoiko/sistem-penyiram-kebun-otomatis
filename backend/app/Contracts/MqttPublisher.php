<?php

namespace App\Contracts;

interface MqttPublisher
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function publish(string $topic, array $payload): void;
}
