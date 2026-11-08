<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('watering_logs', function (Blueprint $table) {
            $table->id();
            $table->string('device_id');
            $table->string('triggered_by', 32);
            $table->unsignedInteger('duration_seconds');
            $table->timestamp('executed_at');

            $table->foreign('device_id')
                ->references('device_id')
                ->on('devices')
                ->cascadeOnDelete();

            $table->index(['device_id', 'executed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('watering_logs');
    }
};
