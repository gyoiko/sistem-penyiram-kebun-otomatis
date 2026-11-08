import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_iot/main.dart';
import 'package:kontrol_iot/models/device.dart';
import 'package:kontrol_iot/models/watering_schedule.dart';
import 'package:kontrol_iot/state/iot_controller.dart';

import 'fake_iot_repository.dart';

void main() {
  final now = DateTime.now();

  FakeIotRepository buildFakeRepository() {
    return FakeIotRepository(
      devices: [
        Device(
          id: 'esp32-depan',
          name: 'Teras Depan',
          location: 'Blok A',
          isOnline: true,
          lastSeen: now,
        ),
        Device(
          id: 'esp32-belakang',
          name: 'Kebun Belakang',
          location: 'Blok B',
          isOnline: true,
          lastSeen: now,
        ),
        Device(
          id: 'esp32-greenhouse',
          name: 'Greenhouse',
          location: 'Blok C',
          isOnline: false,
        ),
      ],
      schedules: {
        'esp32-depan': [
          WateringSchedule(id: 1, deviceId: 'esp32-depan', time: '06:00'),
          WateringSchedule(id: 2, deviceId: 'esp32-depan', time: '18:00'),
        ],
        'esp32-belakang': [
          WateringSchedule(id: 3, deviceId: 'esp32-belakang', time: '06:00'),
          WateringSchedule(id: 4, deviceId: 'esp32-belakang', time: '18:00'),
        ],
        'esp32-greenhouse': [
          WateringSchedule(id: 5, deviceId: 'esp32-greenhouse', time: '06:00'),
          WateringSchedule(id: 6, deviceId: 'esp32-greenhouse', time: '18:00'),
        ],
      },
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iotRepositoryProvider.overrideWithValue(buildFakeRepository()),
        ],
        child: const KontrolIotApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('dashboard menampilkan ringkasan dan daftar perangkat',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Kontrol Kebun'), findsOneWidget);
    expect(find.text('Penyiraman berikutnya'), findsOneWidget);
    expect(find.text('Teras Depan'), findsOneWidget);
    expect(find.text('Kebun Belakang'), findsOneWidget);
    expect(find.text('Nyalakan Lampu'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Greenhouse'), 200);
    expect(find.text('Greenhouse'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('navigasi ke detail dan layar jadwal', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Teras Depan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Lampu Internal'), findsOneWidget);
    expect(find.text('NYALAKAN LAMPU'), findsOneWidget);
    expect(find.text('Status Perangkat'), findsOneWidget);

    await tester.tap(find.text('NYALAKAN LAMPU'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MATIKAN LAMPU'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.event_note_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Jadwal Penyiraman'), findsOneWidget);
    expect(find.text('Jadwal Default'), findsOneWidget);
    expect(find.text('06:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('menampilkan pesan error saat backend tidak terjangkau',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iotRepositoryProvider.overrideWithValue(ThrowingIotRepository()),
        ],
        child: const KontrolIotApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tidak dapat memuat data'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await disposeApp(tester);
  });
}

class ThrowingIotRepository extends FakeIotRepository {
  ThrowingIotRepository();

  @override
  Future<List<Device>> fetchDevices() async {
    throw Exception('Server tidak dapat dijangkau.');
  }
}
