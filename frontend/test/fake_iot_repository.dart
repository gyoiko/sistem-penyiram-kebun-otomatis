import 'dart:async';

import 'package:kontrol_iot/data/iot_repository.dart';
import 'package:kontrol_iot/models/device.dart';
import 'package:kontrol_iot/models/watering_schedule.dart';

class FakeIotRepository implements IotRepository {
  FakeIotRepository({
    List<Device>? devices,
    Map<String, List<WateringSchedule>>? schedules,
  })  : _devices = [...?devices],
        _schedules = {...?schedules};

  final List<Device> _devices;
  final Map<String, List<WateringSchedule>> _schedules;
  final StreamController<IotRealtimeEvent> _events =
      StreamController<IotRealtimeEvent>.broadcast();

  int _nextScheduleId = 100;

  @override
  Stream<IotRealtimeEvent> get events => _events.stream;

  @override
  Future<List<Device>> fetchDevices() async => [..._devices];

  @override
  Future<List<WateringSchedule>> fetchSchedules(String deviceId) async {
    return [...?_schedules[deviceId]];
  }

  @override
  Future<Device> registerDevice({
    required String id,
    required String name,
    required String location,
  }) async {
    final device = Device(
      id: id,
      name: name,
      location: location,
      isOnline: false,
    );
    _devices.add(device);
    _schedules[id] = [
      WateringSchedule(id: _nextScheduleId++, deviceId: id, time: '06:00'),
      WateringSchedule(id: _nextScheduleId++, deviceId: id, time: '18:00'),
    ];
    return device;
  }

  @override
  Future<WateringSchedule> addSchedule(
    String deviceId, {
    required String time,
    int durationSeconds = 60,
  }) async {
    final schedule = WateringSchedule(
      id: _nextScheduleId++,
      deviceId: deviceId,
      time: time,
      durationSeconds: durationSeconds,
      isCustom: true,
    );
    _schedules.putIfAbsent(deviceId, () => []).add(schedule);
    return schedule;
  }

  @override
  Future<void> updateSchedule(
    int id, {
    String? time,
    int? durationSeconds,
    bool? isActive,
  }) async {
    _schedules.updateAll(
      (deviceId, list) => [
        for (final item in list)
          if (item.id == id)
            item.copyWith(
              time: time,
              durationSeconds: durationSeconds,
              isActive: isActive,
            )
          else
            item,
      ],
    );
  }

  @override
  Future<void> deleteSchedule(int id) async {
    _schedules.updateAll(
      (deviceId, list) => [
        for (final item in list)
          if (item.id != id) item,
      ],
    );
  }

  @override
  Future<void> setLamp(String deviceId, {required bool on}) async {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index >= 0) {
      _devices[index] = _devices[index].copyWith(ledOn: on);
    }
  }

  @override
  Future<void> syncSubscriptions(Iterable<String> deviceIds) async {}

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}
