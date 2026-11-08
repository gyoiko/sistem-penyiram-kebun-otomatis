import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/error_utils.dart';
import '../models/device.dart';
import '../screens/device_detail_screen.dart';
import '../state/iot_controller.dart';
import 'status_dot.dart';

class DeviceCard extends ConsumerWidget {
  const DeviceCard({super.key, required this.device});

  final Device device;

  Future<void> _toggleLamp(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(iotControllerProvider.notifier)
          .setLamp(device.id, on: !device.ledOn);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(iotControllerProvider).value;
    final schedules = state?.schedulesFor(device.id) ?? const [];
    final activeCount =
        schedules.where((schedule) => schedule.isActive).length;
    final next = state?.nextScheduleFor(device.id, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: device.ledOn
              ? AppColors.lamp.withValues(alpha: 0.65)
              : scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeviceDetailScreen(deviceId: device.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusDot(online: device.isOnline, size: 8),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: device.isOnline
                            ? AppColors.green
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 23),
                  child: Text(
                    device.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 14),
                _MetaRow(
                  icon: Icons.event_repeat_rounded,
                  text: activeCount == 0
                      ? 'Tidak ada jadwal aktif'
                      : '$activeCount jadwal aktif',
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.schedule_rounded,
                  text: next == null
                      ? 'Tidak ada jadwal aktif'
                      : 'Berikutnya ${next.time} WIB',
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.lightbulb_outline_rounded,
                  text: device.ledOn ? 'Lampu menyala' : 'Lampu mati',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        device.isOnline ? () => _toggleLamp(context, ref) : null,
                    icon: Icon(
                      device.ledOn
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      device.ledOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: device.ledOn
                          ? AppColors.lamp.withValues(alpha: 0.28)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
