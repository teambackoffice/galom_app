import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';

/// Base card: white surface, hairline border, soft shadow, ripple on tap.
class ManagerCard extends StatelessWidget {
  const ManagerCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(MSpace.lg),
    this.margin = EdgeInsets.zero,
    this.color = MColors.surface,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        // The Ink decoration paints the fill; a filled box keeps its own
        // shadow from showing through the card.
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MSpace.radius),
          child: Ink(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(MSpace.radius),
              border: Border.all(color: MColors.border.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0D1B3E),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class ManagerAvatar extends StatelessWidget {
  const ManagerAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.background = MColors.accentSoft,
    this.foreground = MColors.accent,
  });

  final String name;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        MFormat.initials(name),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Icon + text pair used in card metadata rows.
class MetaItem extends StatelessWidget {
  const MetaItem(this.icon, this.text, {super.key, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? MColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MText.meta.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Small labelled value, e.g. "DELIVERY" / "05 Oct 2026".
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: MText.label),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              valueStyle ??
              const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: MColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

/// Titled white section used by detail screens.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      MSpace.lg,
      MSpace.md,
      MSpace.lg,
      MSpace.md,
    ),
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ManagerCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: MSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MSpace.lg,
              MSpace.md,
              MSpace.md,
              MSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(child: Text(title, style: MText.section)),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: MColors.divider),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label/value row inside a [SectionCard]. Optional copy-to-clipboard.
class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.copyable = false,
    this.valueColor,
    this.bold = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;
  final bool bold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: MText.meta)),
          const SizedBox(width: MSpace.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                color: onTap != null
                    ? MColors.accent
                    : (valueColor ?? MColors.textPrimary),
                fontWeight: bold || onTap != null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: MColors.accent,
            ),
          ],
          if (copyable && onTap == null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 14, color: MColors.textMuted),
          ],
        ],
      ),
    );
    if (onTap != null) return InkWell(onTap: onTap, child: row);
    if (!copyable) return row;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label copied')));
      },
      child: row,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: MText.section)),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: MColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                action!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin labelled progress bar (delivery / billing %).
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.label,
    required this.percent,
    this.color = MColors.accent,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: MText.meta.copyWith(fontSize: 11.5)),
            ),
            Text(
              MFormat.percent(percent),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: MColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            color: color,
            backgroundColor: MColors.divider,
          ),
        ),
      ],
    );
  }
}

/// Large title + one-line subtitle at the top of a tab.
class ManagerTabHeader extends StatelessWidget {
  const ManagerTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MSpace.xl,
        MSpace.lg,
        MSpace.xl,
        MSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MText.title.copyWith(fontSize: 24)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: MText.meta.copyWith(fontSize: 13)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A tab page: header above [child], safe-area aware.
class ManagerTabPage extends StatelessWidget {
  const ManagerTabPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagerTabHeader(title: title, subtitle: subtitle),
          Expanded(child: child),
        ],
      ),
    );
  }
}
