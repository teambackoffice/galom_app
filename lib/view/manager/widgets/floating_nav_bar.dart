import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';

class FloatingNavItem {
  const FloatingNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Shows a red count badge on the icon when greater than zero.
  final int badgeCount;
}

/// Floating, rounded bottom navigation bar.
///
/// The selected destination expands into a navy pill showing icon + label;
/// the others show a minimal icon. The pill is sized from the measured
/// label, and falls back to icon-only if the label cannot fit (very narrow
/// screens or large text), so labels are never clipped.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double barHeight = 64;

  /// Smallest width an unselected icon may shrink to (touch target).
  static const double _minItemWidth = 44;
  static const double _pillPadding = 12;
  static const double _iconSize = 22;
  static const double _gap = 6;

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    // Respect the home indicator / gesture area, but keep the bar floating.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle = DefaultTextStyle.of(context).style.merge(labelStyle);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MSpace.md,
        MSpace.sm,
        MSpace.md,
        bottomInset > 0 ? bottomInset : MSpace.md,
      ),
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: MColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: MColors.border.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140D1B3E),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0A0D1B3E),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final total = box.maxWidth;
            final n = items.length;

            // Width the selected pill needs to show its full label.
            final painter = TextPainter(
              text: TextSpan(text: items[currentIndex].label, style: baseStyle),
              textDirection: TextDirection.ltr,
              textScaler: textScaler,
              maxLines: 1,
            )..layout();
            final needed =
                _pillPadding * 2 + _iconSize + _gap + painter.width + 8;
            painter.dispose();

            final maxSelected = total - _minItemWidth * (n - 1);
            final showLabel = needed <= maxSelected;
            // Give the pill what it needs (no more), split the rest evenly.
            final selectedWidth = showLabel
                ? needed.clamp(total / n, maxSelected).toDouble()
                : total / n;
            final otherWidth = (total - selectedWidth) / (n - 1);

            return Row(
              children: [
                for (var i = 0; i < n; i++)
                  AnimatedContainer(
                    duration: _NavButton._duration,
                    curve: _NavButton._curve,
                    width: i == currentIndex ? selectedWidth : otherWidth,
                    child: _NavButton(
                      item: items[i],
                      selected: i == currentIndex,
                      showLabel: showLabel,
                      onTap: () {
                        if (i != currentIndex) HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    Widget icon = AnimatedSwitcher(
      duration: _duration,
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: Icon(
        selected ? item.activeIcon : item.icon,
        key: ValueKey(selected),
        size: FloatingNavBar._iconSize,
        color: selected ? Colors.white : MColors.textMuted,
      ),
    );
    // On the selected tab the page itself shows the count; the badge would
    // only crowd the label.
    if (item.badgeCount > 0 && !selected) {
      icon = Badge(
        label: Text(item.badgeCount > 9 ? '9+' : '${item.badgeCount}'),
        backgroundColor: MColors.red,
        offset: const Offset(7, -5),
        child: icon,
      );
    }
    final semanticsLabel = item.badgeCount > 0
        ? '${item.label}, ${item.badgeCount} pending'
        : item.label;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              height: 44,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? FloatingNavBar._pillPadding : 0,
              ),
              decoration: BoxDecoration(
                color: selected ? MColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  // Label slides open next to the icon when selected.
                  Flexible(
                    child: AnimatedSize(
                      duration: _duration,
                      curve: _curve,
                      child: selected && showLabel
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: FloatingNavBar._gap,
                              ),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: FloatingNavBar.labelStyle,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
