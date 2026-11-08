<?php

namespace Tests\Support;

use App\Contracts\MqttPublisher;

class FakeMqttPublisher implements MqttPublisher
{
    /**
     * @var array<int, array{topic: string, payload: array<string, mixed>}>
     */
    public array $messages = [];

    /**
     * @param  array<string, mixed>  $payload
     */
    public function publish(string $topic, array $payload): void
    {
        $this->messages[] = [
            'topic' => $topic,
            'payload' => $payload,
        ];
    }
}
