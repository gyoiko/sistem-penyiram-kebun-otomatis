import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error_utils.dart';
import '../state/iot_controller.dart';

Future<void> showAddDeviceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddDeviceSheet(),
  );
}

class _AddDeviceSheet extends ConsumerStatefulWidget {
  const _AddDeviceSheet();

  @override
  ConsumerState<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends ConsumerState<_AddDeviceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: 'esp32-');
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(iotControllerProvider.notifier).registerDevice(
            id: _idController.text,
            name: _nameController.text,
            location: _locationController.text,
          );

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Perangkat ditambahkan dengan jadwal default 06:00 & 18:00 WIB',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final devices =
        ref.watch(iotControllerProvider).value?.devices ?? const [];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Perangkat',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Perangkat baru otomatis mendapat jadwal 06:00 dan 18:00 WIB.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _idController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  hintText: 'esp32-depan',
                  prefixIcon: Icon(Icons.memory_rounded),
                ),
                validator: (value) {
                  final text = _normalize(value ?? '');
                  if (text.isEmpty || text == 'esp32-') {
                    return 'Device ID wajib diisi';
                  }
                  if (devices.any((device) => device.id == text)) {
                    return 'Device ID sudah terdaftar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama perangkat',
                  hintText: 'Teras Depan',
                  prefixIcon: Icon(Icons.spa_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nama perangkat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Lokasi (opsional)',
                  hintText: 'Blok A · Pot 1–4',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Daftarkan Perangkat'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
