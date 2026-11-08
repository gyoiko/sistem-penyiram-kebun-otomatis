<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class IngestTelemetryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'device_id' => ['required', 'string', 'max:64', 'alpha_dash'],
            'soil_moisture' => ['required', 'integer', 'min:0', 'max:100'],
            'recorded_at' => ['sometimes', 'date'],
        ];
    }
}
