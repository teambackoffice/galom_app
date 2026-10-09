// Defensive JSON readers for the Manager API.
// Every optional field may be null, "" or an unexpected type, so these
// helpers never throw and never require `!`.

import 'package:intl/intl.dart';

String asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

String? asStringOrNull(dynamic v) {
  final s = asString(v).trim();
  return s.isEmpty ? null : s;
}

double asDouble(dynamic v) => asDoubleOrNull(v) ?? 0;

double? asDoubleOrNull(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool asFlag(dynamic v) => v == 1 || v == true || v == '1';

DateTime? asDateTime(dynamic v) {
  final s = asString(v).trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map(asMap).toList();
}

List<String> asStringList(dynamic v) {
  if (v is! List) return const [];
  return v.map(asStringOrNull).whereType<String>().toList(growable: false);
}

Map<String, double> asTotals(dynamic v) {
  final map = asMap(v);
  final out = <String, double>{};
  map.forEach((k, val) {
    final d = asDoubleOrNull(val);
    if (d != null) out[k] = d;
  });
  return out;
}

/// Parses a visit time such as "10:00:00", "9:05:00" or "9:05:00.123456"
/// and combines it with [date]. Returns null when the time cannot be read.
DateTime? combineDateAndTime(DateTime? date, String rawTime) {
  if (date == null) return null;
  final clean = rawTime.split('.').first.trim();
  if (clean.isEmpty) return null;
  try {
    final t = DateFormat('H:mm:ss').parseStrict(clean);
    return DateTime(
      date.year,
      date.month,
      date.day,
      t.hour,
      t.minute,
      t.second,
    );
  } catch (_) {
    return null;
  }
}
