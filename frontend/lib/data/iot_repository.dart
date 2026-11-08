import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dio/dio.dart';

import '../core/app_config.dart';
import '../models/device.dart';
import '../models/watering_schedule.dart';

sealed class IotRealtimeEvent {
  const IotRealtimeEvent();
}

class DeviceStatusEvent extends IotRealtimeEvent {
  const DeviceStatusEvent({required this.deviceId, required this.isOnline});

  final String deviceId;
  final bool isOnline;
}

class LampStatusEvent extends IotRealtimeEvent {
  const LampStatusEvent({required this.deviceId, required this.on});

  final String deviceId;
  final bool on;
}

abstract class IotRepository {
  Stream<IotRealtimeEvent> get events;

  Future<List<Device>> fetchDevices();

  Future<List<WateringSchedule>> fetchSchedules(String deviceId);

  Future<Device> registerDevice({
    required String id,
    required String name,
    required String location,
  });

  Future<WateringSchedule> addSchedule(
    String deviceId, {
    required String time,
    int durationSeconds = 60,
  });

  Future<void> updateSchedule(
    int id, {
    String? time,
    int? durationSeconds,
    bool? isActive,
  });

  Future<void> deleteSchedule(int id);

  Future<void> setLamp(String deviceId, {required bool on});

  Future<void> syncSubscriptions(Iterable<String> deviceIds);

  Future<void> dispose();
}

class HttpIotRepository implements IotRepository {
  HttpIotRepository({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    _client = PusherChannelsClient.websocket(
      options: PusherChannelsOptions.fromHost(
        scheme: AppConfig.realtimeScheme,
        host: AppConfig.realtimeHost,
        key: AppConfig.realtimeKey,
        port: AppConfig.realtimePort,
      ),
      minimumReconnectDelayDuration: const Duration(seconds: 2),
      connectionErrorHandler: (error, trace, refresh) {
        refresh();
      },
    );

    _connectionSubscription = _client.onConnectionEstablished.listen((_) {
      for (final channel in _channels.values) {
        channel.subscribeIfNotUnsubscribed();
      }
    });

    unawaited(_client.connect());
  }

  final Dio _dio;
  late final PusherChannelsClient _client;

  final _events = StreamController<IotRealtimeEvent>.broadcast();
  final Map<String, PublicChannel> _channels = {};
  final Map<String, StreamSubscription<ChannelReadEvent>> _channelSubscriptions =
      {};
  StreamSubscription<void>? _connectionSubscription;

  @override
  Stream<IotRealtimeEvent> get events => _events.stream;

  @override
  Future<List<Device>> fetchDevices() async {
    final response = await _dio.get<dynamic>('/devices');
    return _list(response, Device.fromJson);
  }

  @override
  Future<List<WateringSchedule>> fetchSchedules(String deviceId) async {
    final response = await _dio.get<dynamic>('/devices/$deviceId/schedules');
    return _list(response, WateringSchedule.fromJson);
  }

  @override
  Future<Device> registerDevice({
    required String id,
    required String name,
    required String location,
  }) async {
    final response = await _dio.post<dynamic>(
      '/devices',
      data: {
        'device_id': id,
        'name': name,
        'location': location,
      },
    );
    return Device.fromJson(_item(response));
  }

  @override
  Future<WateringSchedule> addSchedule(
    String deviceId, {
    required String time,
    int durationSeconds = 60,
  }) async {
    final response = await _dio.post<dynamic>(
      '/devices/$deviceId/schedules',
      data: {
        'watering_time': time,
        'duration_seconds': durationSeconds,
      },
    );
    return WateringSchedule.fromJson(_item(response));
  }

  @override
  Future<void> updateSchedule(
    int id, {
    String? time,
    int? durationSeconds,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (time != null) payload['watering_time'] = time;
    if (durationSeconds != null) payload['duration_seconds'] = durationSeconds;
    if (isActive != null) payload['is_active'] = isActive;

    await _dio.put<dynamic>('/schedules/$id', data: payload);
  }

  @override
  Future<void> deleteSchedule(int id) async {
    await _dio.delete<dynamic>('/schedules/$id');
  }

  @override
  Future<void> setLamp(String deviceId, {required bool on}) async {
    await _dio.put<dynamic>(
      '/devices/$deviceId/lamp',
      data: {'on': on},
    );
  }

  @override
  Future<void> syncSubscriptions(Iterable<String> deviceIds) async {
    final desired = deviceIds.map((id) => 'devices.$id').toSet();

    for (final name in _channels.keys.toList()) {
      if (desired.contains(name)) continue;
      await _channelSubscriptions.remove(name)?.cancel();
      _channels.remove(name)?.unsubscribe();
    }

    for (final name in desired) {
      if (_channels.containsKey(name)) continue;

      final channel = _client.publicChannel(name);
      _channelSubscriptions[name] = channel.bindToAll().listen(_handleEvent);
      channel.subscribeIfNotUnsubscribed();
      _channels[name] = channel;
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _channelSubscriptions.values) {
      await subscription.cancel();
    }
    _channelSubscriptions.clear();
    _channels.clear();

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    await _events.close();

    if (!_client.isDisposed) {
      _client.dispose();
    }
  }

  void _handleEvent(ChannelReadEvent event) {
    final data = event.tryGetDataAsMap();
    if (data == null) return;

    final deviceId = data['device_id'];
    if (deviceId is! String) return;

    switch (event.name) {
      case 'device_status':
        _events.add(
          DeviceStatusEvent(
            deviceId: deviceId,
            isOnline: data['is_online'] as bool? ?? false,
          ),
        );
      case 'lamp_status':
        _events.add(
          LampStatusEvent(
            deviceId: deviceId,
            on: data['on'] as bool? ?? false,
          ),
        );
    }
  }

  List<T> _list<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) decode,
  ) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) return const [];
    final items = payload['data'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) decode(item),
    ];
  }

  Map<String, dynamic> _item(Response<dynamic> response) {
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final item = payload['data'];
      if (item is Map<String, dynamic>) return item;
    }
    throw StateError('Respons API tidak dikenali');
  }
}
