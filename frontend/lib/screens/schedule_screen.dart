import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error_utils.dart';
import '../models/watering_schedule.dart';
import '../state/iot_controller.dart';
import '../widgets/async_error_view.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key, required this.deviceId});

  final String deviceId;

  int _byTime(WateringSchedule a, WateringSchedule b) =>
      a.time.compareTo(b.time);

  Future<void> _addCustomSchedule(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Pilih jam penyiraman',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    try {
      await ref
          .read(iotControllerProvider.notifier)
          .addSchedule(deviceId, time: time);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(iotControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final device = asyncState.value?.deviceById(deviceId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jadwal Penyiraman',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              device?.name ?? deviceId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: asyncState.hasValue
            ? () => _addCustomSchedule(context, ref)
            : null,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Tambah jadwal'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(iotControllerProvider),
        ),
        data: (state) {
          final schedules = state.schedulesFor(deviceId);
          final defaults = schedules
              .where((item) => !item.isCustom)
              .toList()
            ..sort(_byTime);
          final customs = schedules.where((item) => item.isCustom).toList()
            ..sort(_byTime);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Semua jadwal menggunakan zona waktu WIB (GMT+7).',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Jadwal Default',
            subtitle: 'Dibuat otomatis saat perangkat terdaftar',
          ),
          const SizedBox(height: 10),
          for (final schedule in defaults) _ScheduleTile(schedule: schedule),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Jadwal Kustom',
            subtitle: customs.isEmpty
                ? 'Belum ada jadwal tambahan'
                : '${customs.length} jadwal tambahan',
          ),
          const SizedBox(height: 10),
          if (customs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 32,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambahkan jadwal siram di luar 06:00 dan 18:00.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            for (final schedule in customs) _ScheduleTile(schedule: schedule),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ScheduleTile extends ConsumerWidget {
  const _ScheduleTile({required this.schedule});

  final WateringSchedule schedule;

  Future<void> _editDuration(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: schedule.durationSeconds.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Durasi ${schedule.time}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'detik',
            helperText: 'Batas aman 5 – 600 detik',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(int.tryParse(controller.text.trim())),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    try {
      await ref.read(iotControllerProvider.notifier).updateSchedule(
            schedule.id,
            durationSeconds: result.clamp(5, 600).toInt(),
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(iotControllerProvider.notifier)
          .updateSchedule(schedule.id, isActive: value);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(iotControllerProvider.notifier)
          .deleteSchedule(schedule.id);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  schedule.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        schedule.isActive ? scheme.onSurface : scheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _editDuration(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${schedule.durationSeconds} detik',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (schedule.isCustom)
            IconButton(
              tooltip: 'Hapus jadwal',
              onPressed: () => _delete(context, ref),
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          Switch(
            value: schedule.isActive,
            onChanged: (value) => _toggle(context, ref, value),
          ),
        ],
      ),
    );
  }
}
