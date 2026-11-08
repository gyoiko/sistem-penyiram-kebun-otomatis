<?php

namespace App\Console\Commands;

use App\Services\LampService;
use App\Services\TelemetryService;
use App\Support\MqttClientId;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use PhpMqtt\Client\ConnectionSettings;
use PhpMqtt\Client\MqttClient;
use Throwable;

class MqttSubscribe extends Command
{
    protected $signature = 'mqtt:subscribe {--retry-delay=5 : Seconds to wait before reconnecting}';

    protected $description = 'Subscribe to MQTT telemetry and device status topics';

    public function handle(TelemetryService $telemetry, LampService $lamps): int
    {
        $config = config('mqtt');

        if (! $config['enabled']) {
            $this->error('MQTT disabled. Set MQTT_ENABLED=true in .env first.');

            return self::FAILURE;
        }

        $prefix = $config['topic_prefix'];
        $retryDelay = (int) $this->option('retry-delay');
        $hintShown = false;

        while (true) {
            try {
                $client = new MqttClient(
                    host: $config['host'],
                    port: $config['port'],
                    clientId: MqttClientId::make(),
                );

                $settings = (new ConnectionSettings)
                    ->setKeepAliveInterval(30)
                    ->setConnectTimeout(5)
                    ->setSocketTimeout(60);

                if (! empty($config['username'])) {
                    $settings->setUsername($config['username']);
                }

                if (! empty($config['password'])) {
                    $settings->setPassword($config['password']);
                }

                $client->connect($settings, true);

                $client->subscribe(
                    "{$prefix}/+/sensor",
                    function (string $topic, string $message) use ($telemetry, $prefix): void {
                        $deviceId = $this->deviceFromTopic($topic, ['sensor'], $prefix);

                        if ($deviceId === null) {
                            return;
                        }

                        $payload = json_decode($message, true);

                        if (! is_array($payload)) {
                            Log::warning('Invalid MQTT sensor payload', ['topic' => $topic]);

                            return;
                        }

                        $moisture = $payload['soil_moisture'] ?? $payload['moisture'] ?? null;

                        if (! is_numeric($moisture)) {
                            Log::warning('MQTT sensor payload missing soil_moisture', ['topic' => $topic]);

                            return;
                        }

                        $telemetry->ingest($deviceId, (int) $moisture);
                    },
                    MqttClient::QOS_AT_LEAST_ONCE,
                );

                $client->subscribe(
                    "{$prefix}/+/status",
                    function (string $topic, string $message) use ($telemetry, $prefix): void {
                        $deviceId = $this->deviceFromTopic($topic, ['status'], $prefix);

                        if ($deviceId === null) {
                            return;
                        }

                        $payload = json_decode($message, true);
                        $online = is_array($payload) ? ($payload['online'] ?? null) : null;

                        if ($online === null) {
                            return;
                        }

                        $online ? $telemetry->markOnline($deviceId) : $telemetry->markOffline($deviceId);
                    },
                    MqttClient::QOS_AT_LEAST_ONCE,
                );

                $client->subscribe(
                    "{$prefix}/+/lampu/state",
                    function (string $topic, string $message) use ($lamps, $prefix): void {
                        $deviceId = $this->deviceFromTopic($topic, ['lampu', 'state'], $prefix);

                        if ($deviceId === null) {
                            return;
                        }

                        $payload = json_decode($message, true);

                        if (! is_array($payload)) {
                            return;
                        }

                        $on = $payload['on'] ?? null;

                        if (! is_bool($on)) {
                            $state = strtoupper((string) ($payload['state'] ?? ''));
                            $on = match ($state) {
                                'ON' => true,
                                'OFF' => false,
                                default => null,
                            };
                        }

                        if ($on === null) {
                            return;
                        }

                        $lamps->applyReportedState($deviceId, $on);
                    },
                    MqttClient::QOS_AT_LEAST_ONCE,
                );

                $this->info("Subscribed to {$prefix}/+/sensor, {$prefix}/+/status and {$prefix}/+/lampu/state");

                $client->loop(true);

                $client->disconnect();
            } catch (Throwable $exception) {
                Log::error('MQTT listener error', ['message' => $exception->getMessage()]);
                $this->warn('MQTT error: '.$exception->getMessage());

                if (! $hintShown) {
                    $hintShown = true;
                    $this->line('Pastikan broker MQTT berjalan, mis.: npx -y aedes-cli start --host 0.0.0.0 --port 1883');
                }
            }

            sleep($retryDelay);
        }
    }

    /**
     * @param  array<int, string>  $suffix
     */
    private function deviceFromTopic(string $topic, array $suffix, string $prefix): ?string
    {
        $segments = explode('/', $topic);

        if (count($segments) !== count($suffix) + 2 || $segments[0] !== $prefix) {
            return null;
        }

        if (array_slice($segments, 2) !== $suffix) {
            return null;
        }

        return $segments[1];
    }
}
