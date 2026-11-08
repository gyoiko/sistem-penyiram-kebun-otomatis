class WateringSchedule {
  const WateringSchedule({
    required this.id,
    required this.deviceId,
    required this.time,
    this.durationSeconds = 60,
    this.isCustom = false,
    this.isActive = true,
  });

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      time: json['watering_time'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 60,
      isCustom: json['is_custom'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final String deviceId;
  final String time;
  final int durationSeconds;
  final bool isCustom;
  final bool isActive;

  WateringSchedule copyWith({
    String? time,
    int? durationSeconds,
    bool? isActive,
  }) {
    return WateringSchedule(
      id: id,
      deviceId: deviceId,
      time: time ?? this.time,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCustom: isCustom,
      isActive: isActive ?? this.isActive,
    );
  }
}
