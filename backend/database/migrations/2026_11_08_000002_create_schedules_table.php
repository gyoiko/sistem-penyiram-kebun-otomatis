<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('schedules', function (Blueprint $table) {
            $table->id();
            $table->string('device_id');
            $table->string('watering_time', 5);
            $table->unsignedInteger('duration_seconds')->default(60);
            $table->boolean('is_custom')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('device_id')
                ->references('device_id')
                ->on('devices')
                ->cascadeOnDelete();

            $table->index(['watering_time', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('schedules');
    }
};
