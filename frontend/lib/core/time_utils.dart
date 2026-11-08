import 'package:intl/intl.dart';

final DateFormat _clockFormat = DateFormat('HH:mm');

String formatClock(DateTime time) => _clockFormat.format(time);

DateTime? parseApiDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

DateTime nextOccurrence(String hhmm, DateTime from) {
  final parts = hhmm.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  var candidate = DateTime(from.year, from.month, from.day, hour, minute);
  if (!candidate.isAfter(from)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
