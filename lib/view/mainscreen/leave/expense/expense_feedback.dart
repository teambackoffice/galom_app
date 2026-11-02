import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/expense_style.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';

/// Snackbars and confirmation dialogs shared by the Expense Claim screens.

enum ExpenseSnackType { success, error, info }

void showExpenseSnack(
  BuildContext context, {
  required String title,
  String? message,
  ExpenseSnackType type = ExpenseSnackType.info,
}) {
  final (Color color, IconData icon) = switch (type) {
    ExpenseSnackType.success => (
      ExpenseStyle.approved,
      Icons.check_circle_rounded,
    ),
    ExpenseSnackType.error => (ExpenseStyle.rejected, Icons.error_rounded),
    ExpenseSnackType.info => (ComplaintStyle.navy, Icons.info_rounded),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        // No action button: Flutter keeps snackbars with an action open.
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// Centered dialog with an icon badge. Returns true when confirmed.
Future<bool> showExpenseConfirm(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  IconData? confirmIcon,
  Color color = ComplaintStyle.navy,
  Widget? details,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ComplaintStyle.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: ComplaintStyle.muted,
              ),
            ),
            if (details != null) ...[const SizedBox(height: 18), details],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ComplaintStyle.navy,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: ComplaintStyle.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: Icon(confirmIcon ?? icon, size: 18),
                    label: Text(confirmLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}

/// Label / value rows inside a confirm dialog, e.g. count and total.
class ExpenseDialogSummary extends StatelessWidget {
  final List<(String, String)> rows;
  final (String, String)? total;

  const ExpenseDialogSummary({super.key, required this.rows, this.total});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? ComplaintStyle.navy : ComplaintStyle.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: ComplaintStyle.navy,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ComplaintStyle.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows) row(label, value),
          if (total != null) ...[
            const Divider(height: 14, color: ComplaintStyle.border),
            row(total!.$1, total!.$2, bold: true),
          ],
        ],
      ),
    );
  }
}
