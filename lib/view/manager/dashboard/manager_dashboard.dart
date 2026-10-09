import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_dashboard_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_leave_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_profile_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_stock_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/view/manager/leaves/leave_list.dart';
import 'package:location_tracker_app/view/manager/manager_navigation.dart';
import 'package:location_tracker_app/view/manager/profile/manager_profile.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Manager home: greeting, period summary, pending approvals, module
/// shortcuts and recent activity. Every figure comes from the API
/// (`total_count` / `totals` for the selected period).
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ManagerDashboardController>().ensureLoaded();
      context.read<ManagerLeaveController>().ensureLoaded();
      context.read<ManagerStockController>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<ManagerDashboardController>();
    final profile = context.watch<ManagerProfileController>().profile;
    final pendingLeaves = context.select<ManagerLeaveController, int>(
      (c) => c.pendingCount,
    );

    return RefreshIndicator(
      color: MColors.accent,
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: () => Future.wait([
        dash.load(),
        context.read<ManagerLeaveController>().load(),
        context.read<ManagerStockController>().load(),
      ]),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeroSection(name: profile?.displayName, dash: dash),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              MSpace.lg,
              MSpace.lg,
              MSpace.lg,
              MSpace.xl,
            ),
            sliver: SliverList.list(
              children: [
                if (pendingLeaves > 0) ...[
                  _AttentionBanner(
                    count: pendingLeaves,
                    onTap: () => openLeaveRequests(context),
                  ),
                  const SizedBox(height: MSpace.xl),
                ],
                const SectionHeader('Quick access'),
                _ModuleGrid(dash: dash, pendingLeaves: pendingLeaves),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header + overlapping summary card
// -----------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.name, required this.dash});

  final String? name;
  final ManagerDashboardController dash;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final displayName = (name == null || name!.isEmpty) ? null : name!;
    final faded = Colors.white.withValues(alpha: 0.72);

    return Stack(
      children: [
        // Navy backdrop stops part-way down the summary card so the card
        // appears to float over the header.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MColors.navy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            MSpace.xl,
            top + MSpace.lg,
            MSpace.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName == null ? _greeting : '$_greeting,',
                          style: TextStyle(color: faded, fontSize: 14),
                        ),
                        if (displayName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: MColors.accent.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sales Team Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: MSpace.md),
                  // Profile & settings live behind this button.
                  Material(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Profile & settings',
                      onPressed: () => openManagerProfile(context),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      iconSize: 24,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpace.xl),
              _PeriodSelector(period: dash.period, onChanged: dash.setPeriod),
              const SizedBox(height: MSpace.lg),
              _SummaryCard(dash: dash),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / DashboardPeriod.values.length;
          return Stack(
            children: [
              // Sliding highlight behind the selected period.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * period.index,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final p in DashboardPeriod.values)
                    Expanded(
                      child: Semantics(
                        selected: p == period,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(p),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              // Merge so the app's font family is kept.
                              style: DefaultTextStyle.of(context).style.merge(
                                TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p == period
                                      ? MColors.navy
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              child: Text(p.label),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// White card: collections up top, then orders / billed / outstanding.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.dash});
  final ManagerDashboardController dash;

  @override
  Widget build(BuildContext context) {
    final range = dash.range;
    final pay = dash.summary(ManagerModule.payments);
    final orders = dash.summary(ManagerModule.salesOrders);
    final inv = dash.summary(ManagerModule.salesInvoices);

    return Container(
      decoration: BoxDecoration(
        color: MColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D1B3E),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              onTap: pay.error != null
                  ? () => dash.retry(ManagerModule.payments)
                  : () => openManagerModule(
                      context,
                      ManagerModule.payments,
                      range: range,
                    ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collected · ${MFormat.range(range.start, range.end)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MText.meta.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _Value(
                            summary: pay,
                            text: MFormat.money(pay.totals['paid_amount'] ?? 0),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: MColors.textPrimary,
                              letterSpacing: -0.6,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (pay.hasData) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${MFormat.count(pay.totalCount)} customer receipt${pay.totalCount == 1 ? '' : 's'}',
                              style: MText.meta.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MColors.greenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: MColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: MColors.divider),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Orders',
                      summary: orders,
                      value: MFormat.moneyCompact(
                        orders.totals['grand_total'] ?? 0,
                      ),
                      onTap: () => openManagerModule(
                        context,
                        ManagerModule.salesOrders,
                        range: range,
                      ),
                      onRetry: () => dash.retry(ManagerModule.salesOrders),
                      radius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: MColors.divider),
                  Expanded(
                    child: _MiniStat(
                      label: 'Billed',
                      summary: inv,
                      value: MFormat.moneyCompact(
                        inv.totals['grand_total'] ?? 0,
                      ),
                      onTap: () => openManagerModule(
                        context,
                        ManagerModule.salesInvoices,
                        range: range,
                      ),
                      onRetry: () => dash.retry(ManagerModule.salesInvoices),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: MColors.divider),
                  Expanded(
                    child: _MiniStat(
                      label: 'Outstanding',
                      summary: inv,
                      value: MFormat.moneyCompact(
                        inv.totals['outstanding_amount'] ?? 0,
                      ),
                      valueColor: MColors.orange,
                      onTap: () => openManagerModule(
                        context,
                        ManagerModule.salesInvoices,
                        range: range,
                      ),
                      onRetry: () => dash.retry(ManagerModule.salesInvoices),
                      radius: const BorderRadius.only(
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Value with shimmer while loading and a retry hint on error.
class _Value extends StatelessWidget {
  const _Value({
    required this.summary,
    required this.text,
    required this.style,
  });

  final ModuleSummary summary;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (summary.isLoading) {
      return _ShimmerBar(width: 120, height: (style.fontSize ?? 16) * 0.9);
    }
    if (summary.error != null) {
      return const Text(
        "Couldn't load · Tap to retry",
        style: TextStyle(
          fontSize: 12,
          color: MColors.red,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(text, key: ValueKey(text), style: style),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.summary,
    required this.value,
    required this.onTap,
    required this.onRetry,
    this.valueColor,
    this.radius,
  });

  final String label;
  final ModuleSummary summary;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: radius,
      onTap: summary.error != null ? onRetry : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MText.meta.copyWith(fontSize: 11.5),
            ),
            const SizedBox(height: 3),
            if (summary.isLoading)
              const _ShimmerBar(width: 56, height: 14)
            else if (summary.error != null)
              const Icon(Icons.refresh_rounded, size: 18, color: MColors.red)
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: MText.amount.copyWith(
                    fontSize: 15,
                    color: valueColor ?? MColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EDF3),
      highlightColor: const Color(0xFFF7F9FC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pending approvals
// -----------------------------------------------------------------------------

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MColors.orangeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note_rounded, color: MColors.orange),
          ),
          const SizedBox(width: MSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1 ? '1 leave request' : '$count leave requests',
                  style: MText.cardTitle,
                ),
                const SizedBox(height: 2),
                const Text('Waiting for your approval', style: MText.meta),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: MColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Review',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Module shortcuts (two-column grid)
// -----------------------------------------------------------------------------

class _Shortcut {
  const _Shortcut({
    required this.title,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.summary,
    this.caption,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final ModuleSummary? summary;
  final String Function(ModuleSummary s)? caption;
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.dash, required this.pendingLeaves});

  final ManagerDashboardController dash;
  final int pendingLeaves;

  @override
  Widget build(BuildContext context) {
    final range = dash.range;
    String n(int c, String one, String many) =>
        '${MFormat.count(c)} ${c == 1 ? one : many}';

    _Shortcut module(
      ManagerModule m,
      String Function(ModuleSummary s) caption,
    ) => _Shortcut(
      title: m.title,
      icon: m.icon,
      tint: m.tint,
      summary: dash.summary(m),
      caption: caption,
      onTap: () => openManagerModule(context, m, range: range),
    );

    final leaveLoaded = context.select<ManagerLeaveController, bool>(
      (c) => c.hasLoaded,
    );
    final stock = context.watch<ManagerStockController>();

    final items = [
      module(
        ManagerModule.attendance,
        (s) => n(s.totalCount, 'record', 'records'),
      ),
      module(ManagerModule.visits, (s) => n(s.totalCount, 'visit', 'visits')),
      module(
        ManagerModule.salesOrders,
        (s) => n(s.totalCount, 'order', 'orders'),
      ),
      module(
        ManagerModule.salesInvoices,
        (s) => n(s.totalCount, 'invoice', 'invoices'),
      ),
      module(
        ManagerModule.payments,
        (s) => n(s.totalCount, 'receipt', 'receipts'),
      ),
      module(
        ManagerModule.salesReturns,
        (s) =>
            '${n(s.totalCount, 'return', 'returns')} · ${MFormat.moneyCompact(s.totals['grand_total'] ?? 0)}',
      ),
      _Shortcut(
        title: 'Stock',
        icon: Icons.inventory_2_outlined,
        tint: MColors.accent,
        onTap: () =>
            context.read<ManagerNavController>().goTo(ManagerTab.stock),
        summary: stock.error != null && !stock.hasLoaded
            ? ModuleSummary(error: stock.error!.message)
            : !stock.hasLoaded
            ? const ModuleSummary.loading()
            : const ModuleSummary(),
        caption: (_) =>
            '${stock.count(StockFilter.low)} low · ${stock.count(StockFilter.out)} out',
      ),
      _Shortcut(
        title: 'Leave Requests',
        icon: Icons.event_note_outlined,
        tint: MColors.orange,
        onTap: () => openLeaveRequests(context),
        caption: (_) => !leaveLoaded
            ? ''
            : pendingLeaves == 0
            ? 'Nothing pending'
            : '$pendingLeaves pending',
        summary: const ModuleSummary(),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      if (i > 0) rows.add(const SizedBox(height: MSpace.md));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: MSpace.md),
                Expanded(
                  child: i + j < items.length
                      ? _ShortcutTile(item: items[i + j])
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.item});
  final _Shortcut item;

  @override
  Widget build(BuildContext context) {
    final s = item.summary;
    Widget caption;
    if (s == null || s.isLoading) {
      caption = const _ShimmerBar(width: 64, height: 10);
    } else if (s.error != null) {
      caption = const Text(
        'Unavailable',
        style: TextStyle(fontSize: 12, color: MColors.red),
      );
    } else {
      caption = Text(
        item.caption?.call(s) ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: MText.meta.copyWith(fontSize: 12),
      );
    }

    return Semantics(
      button: true,
      label: item.title,
      child: ManagerCard(
        onTap: item.onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.tint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.tint, size: 21),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: MColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: MSpace.md),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MText.cardTitle.copyWith(fontSize: 14.5),
            ),
            const SizedBox(height: 3),
            caption,
          ],
        ),
      ),
    );
  }
}
