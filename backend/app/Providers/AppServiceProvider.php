<?php

namespace App\Providers;

use App\Contracts\MqttPublisher;
use App\Services\Mqtt\LogMqttPublisher;
use App\Services\Mqtt\PhpMqttPublisher;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(MqttPublisher::class, function (Application $app): MqttPublisher {
            $config = $app['config']->get('mqtt');

            return $config['enabled']
                ? new PhpMqttPublisher($config)
                : new LogMqttPublisher;
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
