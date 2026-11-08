import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/iot_repository.dart';
import '../models/watering_schedule.dart';
import 'iot_state.dart';

final iotRepositoryProvider = Provider<IotRepository>((ref) {
  final repository = HttpIotRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final iotControllerProvider = AsyncNotifierProvider<IotController, IotState>(
  IotController.new,
  retry: (retryCount, error) => null,
);

class IotController extends AsyncNotifier<IotState> {
  StreamSubscription<IotRealtimeEvent>? _eventSubscription;

  @override
  Future<IotState> build() {
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _eventSubscription = null;
    });

    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> registerDevice({
    required String id,
    required String name,
    required String location,
  }) async {
    final repository = ref.read(iotRepositoryProvider);
    final device = await repository.registerDevice(
      id: id,
      name: name,
      location: location,
    );
    final schedules = await repository.fetchSchedules(device.id);

    _update(
      (current) => current.copyWith(
        devices: [...current.devices, device],
        schedules: {...current.schedules, device.id: schedules},
      ),
    );

    final current = state.value;
    if (current != null) {
      await repository.syncSubscriptions(
        current.devices.map((item) => item.id),
      );
    }
  }

  Future<void> addSchedule(
    String deviceId, {
    required String time,
    int durationSeconds = 60,
  }) async {
    final schedule = await ref.read(iotRepositoryProvider).addSchedule(
          deviceId,
          time: time,
          durationSeconds: durationSeconds,
        );

    _update(
      (current) => current.copyWith(
        schedules: {
          ...current.schedules,
          deviceId: [...current.schedulesFor(deviceId), schedule],
        },
      ),
    );
  }

  Future<void> updateSchedule(
    int id, {
    String? time,
    int? durationSeconds,
    bool? isActive,
  }) async {
    await ref.read(iotRepositoryProvider).updateSchedule(
          id,
          time: time,
          durationSeconds: durationSeconds,
          isActive: isActive,
        );

    _update((current) {
      final schedules = <String, List<WateringSchedule>>{};
      current.schedules.forEach((deviceId, list) {
        schedules[deviceId] = [
          for (final item in list)
            if (item.id == id)
              item.copyWith(
                time: time,
                durationSeconds: durationSeconds,
                isActive: isActive,
              )
            else
              item,
        ];
      });
      return current.copyWith(schedules: schedules);
    });
  }

  Future<void> deleteSchedule(int id) async {
    await ref.read(iotRepositoryProvider).deleteSchedule(id);

    _update((current) {
      final schedules = <String, List<WateringSchedule>>{};
      current.schedules.forEach((deviceId, list) {
        schedules[deviceId] = [
          for (final item in list)
            if (!(item.id == id && item.isCustom)) item,
        ];
      });
      return current.copyWith(schedules: schedules);
    });
  }

  Future<void> setLamp(String deviceId, {required bool on}) async {
    await ref.read(iotRepositoryProvider).setLamp(deviceId, on: on);

    _update(
      (current) => current.copyWith(
        devices: [
          for (final device in current.devices)
            if (device.id == deviceId)
              device.copyWith(ledOn: on)
            else
              device,
        ],
      ),
    );
  }

  Future<IotState> _load() async {
    final repository = ref.read(iotRepositoryProvider);
    _eventSubscription ??= repository.events.listen(_onEvent);

    final devices = await repository.fetchDevices();
    final schedules = <String, List<WateringSchedule>>{};

    await Future.wait([
      for (final device in devices)
        repository.fetchSchedules(device.id).then((items) {
          schedules[device.id] = items;
        }),
    ]);

    await repository.syncSubscriptions(devices.map((device) => device.id));

    return IotState(devices: devices, schedules: schedules);
  }

  void _onEvent(IotRealtimeEvent event) {
    switch (event) {
      case final DeviceStatusEvent status:
        _update(
          (current) => current.copyWith(
            devices: [
              for (final device in current.devices)
                if (device.id == status.deviceId)
                  device.copyWith(isOnline: status.isOnline)
                else
                  device,
            ],
          ),
        );
      case final LampStatusEvent lamp:
        _update(
          (current) => current.copyWith(
            devices: [
              for (final device in current.devices)
                if (device.id == lamp.deviceId)
                  device.copyWith(ledOn: lamp.on)
                else
                  device,
            ],
          ),
        );
    }
  }

  void _update(IotState Function(IotState current) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(transform(current));
  }
}
