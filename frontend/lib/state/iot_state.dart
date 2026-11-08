import '../core/time_utils.dart';
import '../models/device.dart';
import '../models/watering_schedule.dart';

typedef NextWatering = ({
  Device device,
  WateringSchedule schedule,
  DateTime at,
});

class IotState {
  const IotState({
    required this.devices,
    required this.schedules,
  });

  final List<Device> devices;
  final Map<String, List<WateringSchedule>> schedules;

  int get onlineCount => devices.where((device) => device.isOnline).length;

  int get activeScheduleCount {
    var count = 0;
    for (final list in schedules.values) {
      count += list.where((schedule) => schedule.isActive).length;
    }
    return count;
  }

  Device? deviceById(String id) {
    for (final device in devices) {
      if (device.id == id) return device;
    }
    return null;
  }

  List<WateringSchedule> schedulesFor(String deviceId) =>
      schedules[deviceId] ?? const [];

  WateringSchedule? nextScheduleFor(String deviceId, DateTime from) {
    final active = schedulesFor(deviceId).where((item) => item.isActive);
    WateringSchedule? best;
    Duration? bestDelta;
    for (final item in active) {
      final delta = nextOccurrence(item.time, from).difference(from);
      if (bestDelta == null || delta < bestDelta) {
        bestDelta = delta;
        best = item;
      }
    }
    return best;
  }

  NextWatering? nextWatering(DateTime from) {
    NextWatering? best;

    for (final device in devices) {
      for (final schedule in schedulesFor(device.id)) {
        if (!schedule.isActive) continue;

        final at = nextOccurrence(schedule.time, from);
        if (best == null || at.isBefore(best.at)) {
          best = (device: device, schedule: schedule, at: at);
        }
      }
    }

    return best;
  }

  IotState copyWith({
    List<Device>? devices,
    Map<String, List<WateringSchedule>>? schedules,
  }) {
    return IotState(
      devices: devices ?? this.devices,
      schedules: schedules ?? this.schedules,
    );
  }
}
