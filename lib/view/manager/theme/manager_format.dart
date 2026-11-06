import 'package:intl/intl.dart';

/// Display formatting for the Manager screens (INR, Indian grouping).
class MFormat {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );
  static final NumberFormat _qty = NumberFormat('#,##0.###', 'en_IN');
  static final NumberFormat _pct = NumberFormat('##0.#', 'en_IN');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDate = DateFormat('dd MMM');
  static final DateFormat _weekdayDate = DateFormat('EEE, dd MMM yyyy');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String money(double? v) => v == null ? '—' : _currency.format(v);

  /// Short form for KPI tiles, e.g. ₹1.2L. Falls back to full format for
  /// small values so they never look rounded away.
  static String moneyCompact(double? v) {
    if (v == null) return '—';
    if (v.abs() < 100000) return _whole.format(v);
    return _compact.format(v);
  }

  static final NumberFormat _whole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String qty(double v) => _qty.format(v);
  static String percent(double v) => '${_pct.format(v)}%';

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String shortDate(DateTime? d) =>
      d == null ? '—' : _shortDate.format(d);
  static String weekdayDate(DateTime? d) =>
      d == null ? '—' : _weekdayDate.format(d);
  static String time(DateTime? d) => d == null ? '—' : _time.format(d);
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);

  static String coordinate(double v) => v.toStringAsFixed(5);

  static String count(int n) => NumberFormat.decimalPattern('en_IN').format(n);

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String range(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return _date.format(start);
    }
    if (start.year == end.year) {
      return '${_shortDate.format(start)} – ${_date.format(end)}';
    }
    return '${_date.format(start)} – ${_date.format(end)}';
  }
}
