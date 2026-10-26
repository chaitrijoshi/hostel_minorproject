import 'package:intl/intl.dart';

/// Turns the ISO datetime strings the Django API returns into something
/// readable, e.g. "16 Sep 2026, 04:17 PM". Falls back to the raw string
/// (or "-") if parsing fails.
String formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return iso;
  }
}
