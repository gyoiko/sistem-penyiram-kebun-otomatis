<?php

namespace App\Services\Mqtt;

use App\Contracts\MqttPublisher;
use App\Support\MqttClientId;
use PhpMqtt\Client\ConnectionSettings;
use PhpMqtt\Client\MqttClient;

class PhpMqttPublisher implements MqttPublisher
{
    /**
     * @param  array<string, mixed>  $config
     */
    public function __construct(private readonly array $config) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function publish(string $topic, array $payload): void
    {
        $client = new MqttClient(
            host: $this->config['host'],
            port: $this->config['port'],
            clientId: MqttClientId::make(),
        );

        $settings = (new ConnectionSettings)
            ->setConnectTimeout(5)
            ->setSocketTimeout(5)
            ->setKeepAliveInterval(30);

        if (! empty($this->config['username'])) {
            $settings->setUsername($this->config['username']);
        }

        if (! empty($this->config['password'])) {
            $settings->setPassword($this->config['password']);
        }

        $client->connect($settings, true);

        try {
            $client->publish(
                $topic,
                json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR),
                MqttClient::QOS_AT_LEAST_ONCE,
            );
        } finally {
            $client->disconnect();
        }
    }
}
