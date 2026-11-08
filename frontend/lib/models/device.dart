import '../core/time_utils.dart';

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.location,
    required this.isOnline,
    this.ledOn = false,
    this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['device_id'] as String,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      ledOn: json['led_on'] as bool? ?? false,
      lastSeen: parseApiDate(json['last_seen_at']),
    );
  }

  final String id;
  final String name;
  final String location;
  final bool isOnline;
  final bool ledOn;
  final DateTime? lastSeen;

  Device copyWith({
    String? name,
    String? location,
    bool? isOnline,
    bool? ledOn,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      ledOn: ledOn ?? this.ledOn,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
