import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Colours and formatters for the Expense Claim screens. Shared layout
/// widgets (app bar, pill, private image) come from complaint_style.dart.
class ExpenseStyle {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final NumberFormat _inrShort = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String money(double v) => _inr.format(v);

  /// Whole rupees when there are no paise, for compact tiles.
  static String moneyShort(double v) =>
      v == v.roundToDouble() ? _inrShort.format(v) : _inr.format(v);

  static const pending = Color(0xFFF57F17);
  static const approved = Color(0xFF00875A);
  static const rejected = Color(0xFFB71C1C);

  /// Colour for the label from `expenseStatusLabel` (Pending/Approved/Rejected).
  static Color statusColor(String label) {
    switch (label) {
      case 'Approved':
        return approved;
      case 'Rejected':
        return rejected;
      case 'Pending':
        return pending;
      default:
        return const Color(0xFF546E7A);
    }
  }

  static IconData statusIcon(String label) {
    switch (label) {
      case 'Approved':
        return Icons.check_circle_outline_rounded;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  static IconData typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('travel') || t.contains('fuel') || t.contains('bus')) {
      return Icons.directions_car_outlined;
    }
    if (t.contains('food') || t.contains('meal')) {
      return Icons.restaurant_outlined;
    }
    if (t.contains('hotel') || t.contains('stay') || t.contains('lodg')) {
      return Icons.hotel_outlined;
    }
    if (t.contains('phone') || t.contains('mobile') || t.contains('call')) {
      return Icons.phone_android_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  static String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
