import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/error_utils.dart';
import '../core/time_utils.dart';
import '../models/device.dart';
import '../models/watering_schedule.dart';
import '../state/iot_controller.dart';
import '../widgets/async_error_view.dart';
import '../widgets/status_dot.dart';
import 'schedule_screen.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  Future<void> _setLamp(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool on,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(iotControllerProvider.notifier).setLamp(device.id, on: on);
      messenger.showSnackBar(
        SnackBar(content: Text(on ? 'Lampu dinyalakan' : 'Lampu dimatikan')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(iotControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = asyncState.value;

    if (state == null) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(deviceId),
        ),
        body: asyncState.hasError
            ? AsyncErrorView(
                error: asyncState.error!,
                onRetry: () => ref.invalidate(iotControllerProvider),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final device = state.deviceById(deviceId);

    if (device == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Perangkat tidak ditemukan')),
      );
    }

    final schedules = [...state.schedulesFor(device.id)]
      ..sort((a, b) => a.time.compareTo(b.time));
    final next = state.nextScheduleFor(device.id, DateTime.now());
    final lastSeen = device.lastSeen;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              device.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              device.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScheduleScreen(deviceId: device.id),
              ),
            ),
            icon: const Icon(Icons.event_note_rounded),
            tooltip: 'Kelola jadwal',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: device.ledOn
                            ? AppColors.lamp.withValues(alpha: 0.22)
                            : scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        device.ledOn
                            ? Icons.lightbulb_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: device.ledOn
                            ? AppColors.lamp
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lampu Internal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.ledOn ? 'ON' : 'OFF',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: device.ledOn
                            ? AppColors.lamp
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Mengontrol LED bawaan board (GPIO2).',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: device.isOnline
                        ? () => _setLamp(context, ref, device, !device.ledOn)
                        : null,
                    icon: Icon(
                      device.ledOn
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                    ),
                    label: Text(
                      device.ledOn ? 'MATIKAN LAMPU' : 'NYALAKAN LAMPU',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: device.ledOn ? AppColors.lamp : null,
                      foregroundColor:
                          device.ledOn ? const Color(0xFF3E2A00) : null,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                if (!device.isOnline) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Perangkat sedang offline — perintah tidak dapat dikirim.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Jadwal Penyiraman',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ScheduleScreen(deviceId: device.id),
                        ),
                      ),
                      child: const Text('Kelola'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (schedules.isEmpty)
                  Text(
                    'Belum ada jadwal.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final schedule in schedules)
                        _ScheduleChip(schedule: schedule),
                    ],
                  ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          next == null
                              ? 'Tidak ada jadwal aktif'
                              : 'Berikutnya ${next.time} WIB · ${next.durationSeconds} detik',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Perangkat',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.wifi_rounded,
                  label: 'Koneksi',
                  value: device.isOnline ? 'Online' : 'Offline',
                  valueColor:
                      device.isOnline ? AppColors.green : scheme.onSurfaceVariant,
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Terakhir terlihat',
                  value: lastSeen == null
                      ? 'Belum ada'
                      : '${formatClock(lastSeen)} WIB',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.memory_rounded,
                  label: 'Device ID',
                  value: device.id,
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Lampu',
                  value: device.ledOn ? 'Menyala' : 'Mati',
                  valueColor: device.ledOn ? AppColors.lamp : null,
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    StatusDot(online: device.isOnline, size: 7),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.isOnline
                            ? 'Perangkat terhubung ke broker MQTT'
                            : 'Perangkat tidak terhubung',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({required this.schedule});

  final WateringSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = schedule.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.time,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: active ? scheme.primary : scheme.outline,
            ),
          ),
          Text(
            '${schedule.durationSeconds} detik · ${schedule.isCustom ? 'kustom' : 'default'}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }
}
