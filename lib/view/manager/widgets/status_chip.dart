import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';

/// Colour pair for a status value (spec section 9 colour table).
({Color fg, Color bg}) statusColors(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
    case 'completed':
    case 'present':
    case 'submitted':
    case 'checked out':
    case 'work from home':
    case 'approved':
    case 'in stock':
      return (fg: MColors.green, bg: MColors.greenBg);
    case 'unpaid':
    case 'partly paid':
    case 'to bill':
    case 'to deliver':
    case 'to deliver and bill':
    case 'on hold':
    case 'checked in':
    case 'half day':
    case 'checked out (no check-in)':
    case 'pending':
    case 'open':
    case 'low stock':
      return (fg: MColors.orange, bg: MColors.orangeBg);
    case 'overdue':
    case 'cancelled':
    case 'absent':
    case 'closed':
    case 'rejected':
    case 'out of stock':
      return (fg: MColors.red, bg: MColors.redBg);
    case 'return':
    case 'credit note issued':
    case 'on leave':
      return (fg: MColors.purple, bg: MColors.purpleBg);
    default:
      return (fg: MColors.grey, bg: MColors.greyBg);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9,
          vertical: dense ? 2.5 : 4,
        ),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.fg,
                  fontSize: dense ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small neutral tag, e.g. "First Counter", "Cash".
class MBadge extends StatelessWidget {
  const MBadge(
    this.text, {
    super.key,
    this.icon,
    this.color = MColors.accent,
    this.background,
  });

  final String text;
  final IconData? icon;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
