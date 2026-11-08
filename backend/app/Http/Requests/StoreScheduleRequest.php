<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreScheduleRequest extends FormRequest
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
            'watering_time' => ['required', 'date_format:H:i'],
            'duration_seconds' => ['sometimes', 'integer', 'min:5', 'max:600'],
        ];
    }
}
