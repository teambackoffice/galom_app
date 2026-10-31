import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Colours and small widgets shared by the Customer Complaint screens.
/// Palette matches the Attendance page.
class ComplaintStyle {
  static const navy = Color(0xFF0D1B3E);
  static const background = Color(0xFFF0F2F8);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE3E7F0);

  static Color statusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF1E88E5);
      case 'In Progress':
        return const Color(0xFFF57F17);
      case 'Resolved':
        return const Color(0xFF00875A);
      case 'Closed':
        return const Color(0xFF546E7A);
      default:
        return muted;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'Open':
        return Icons.mark_email_unread_outlined;
      case 'In Progress':
        return Icons.autorenew_rounded;
      case 'Resolved':
        return Icons.check_circle_outline_rounded;
      case 'Closed':
        return Icons.lock_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFB71C1C);
      case 'Medium':
        return const Color(0xFFF57F17);
      case 'Low':
        return const Color(0xFF00875A);
      default:
        return muted;
    }
  }

  static IconData typeIcon(String type) {
    switch (type) {
      case 'Product Quality':
        return Icons.inventory_2_outlined;
      case 'Delivery':
        return Icons.local_shipping_outlined;
      case 'Billing':
        return Icons.receipt_long_outlined;
      case 'Pricing':
        return Icons.sell_outlined;
      case 'Service':
        return Icons.support_agent_outlined;
      default:
        return Icons.report_gmailerrorred_outlined;
    }
  }

  static String formatDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMM yyyy').format(d);

  static String formatDateTime(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(d);

  static BoxDecoration card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

class ComplaintPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ComplaintPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;

  const ComplaintAppBar({super.key, required this.title, this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ComplaintStyle.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: ComplaintStyle.navy,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ComplaintStyle.navy,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: ComplaintStyle.muted),
            ),
        ],
      ),
    );
  }
}

/// Loads a private ERPNext file by sending the session cookie.
class ComplaintAttachmentImage extends StatelessWidget {
  final String url;
  final String? sid;
  final double height;

  const ComplaintAttachmentImage({
    super.key,
    required this.url,
    required this.sid,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        headers: sid == null ? null : {'Cookie': 'sid=$sid'},
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                height: height,
                color: ComplaintStyle.background,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: ComplaintStyle.background,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: ComplaintStyle.muted),
              SizedBox(height: 6),
              Text(
                'Could not load attachment',
                style: TextStyle(fontSize: 12, color: ComplaintStyle.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
