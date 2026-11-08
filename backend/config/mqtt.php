<?php

return [

    /*
    |--------------------------------------------------------------------------
    | MQTT Broker
    |--------------------------------------------------------------------------
    |
    | Konfigurasi koneksi ke broker MQTT. Bila MQTT_ENABLED=false, perintah
    | hanya dicatat ke log (berguna untuk pengembangan lokal tanpa broker).
    |
    */

    'enabled' => (bool) env('MQTT_ENABLED', false),

    'host' => env('MQTT_HOST', '127.0.0.1'),

    'port' => (int) env('MQTT_PORT', 1883),

    'username' => env('MQTT_USERNAME'),

    'password' => env('MQTT_PASSWORD'),

    'client_id_prefix' => env('MQTT_CLIENT_ID_PREFIX', 'laravel-kebun'),

    'topic_prefix' => env('MQTT_TOPIC_PREFIX', 'kebun'),

    /*
    |--------------------------------------------------------------------------
    | Auto Register
    |--------------------------------------------------------------------------
    |
    | Bila true, device yang mengirim telemetri tanpa terdaftar akan otomatis
    | dibuat beserta jadwal default. Set false bila device harus didaftarkan
    | lebih dulu lewat aplikasi.
    |
    */

    'auto_register' => (bool) env('MQTT_AUTO_REGISTER', true),

];
