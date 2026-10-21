import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_stock_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_stock_modal.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/state_views.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';
import 'package:provider/provider.dart';

String _qty(StockItem i) => '${MFormat.qty(i.totalQty)} ${i.uom}'.trim();

class ManagerStockScreen extends StatefulWidget {
  const ManagerStockScreen({super.key});

  @override
  State<ManagerStockScreen> createState() => _ManagerStockScreenState();
}

class _ManagerStockScreenState extends State<ManagerStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ManagerStockController>().ensureLoaded();
    });
  }

  Future<void> _pickThreshold(ManagerStockController c) async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MSpace.xl,
                0,
                MSpace.xl,
                MSpace.xs,
              ),
              child: Text(
                'Low stock limit',
                style: MText.section.copyWith(fontSize: 17),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(MSpace.xl, 0, MSpace.xl, MSpace.sm),
              child: Text(
                'Items with a total quantity at or below this are marked low.',
                style: MText.meta,
              ),
            ),
            for (final t in ManagerStockController.thresholdOptions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MSpace.xl,
                ),
                title: Text('${MFormat.qty(t)} or fewer'),
                trailing: t == c.lowThreshold
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: MColors.accent,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
            const SizedBox(height: MSpace.md),
          ],
        ),
      ),
    );
    if (picked != null) c.setLowThreshold(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ManagerStockController>();
    final subtitle = !c.hasLoaded
        ? 'Inventory across warehouses'
        : '${MFormat.count(c.count(StockFilter.all))} items · '
              '${MFormat.count(c.count(StockFilter.low))} low · '
              '${MFormat.count(c.count(StockFilter.out))} out of stock';

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagerTabHeader(title: 'Stock', subtitle: subtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpace.lg),
            child: TextField(
              onChanged: c.setSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search item name or code',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: MColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: MSpace.lg,
                vertical: MSpace.sm,
              ),
              children: [
                for (final f in StockFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: MSpace.sm),
                    child: _Chip(
                      label: c.hasLoaded
                          ? '${f.label} ${MFormat.count(c.count(f))}'
                          : f.label,
                      selected: c.filter == f,
                      dotColor: switch (f) {
                        StockFilter.all => null,
                        StockFilter.low => MColors.orange,
                        StockFilter.out => MColors.red,
                      },
                      onTap: () => c.setFilter(f),
                    ),
                  ),
                _Chip(
                  label: 'Low ≤ ${MFormat.qty(c.lowThreshold)}',
                  icon: Icons.tune_rounded,
                  selected: false,
                  onTap: () => _pickThreshold(c),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: MColors.accent,
              onRefresh: c.load,
              child: _body(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(ManagerStockController c) {
    Widget centered(Widget child) => LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: child),
        ),
      ),
    );

    if (c.isLoading && !c.hasLoaded) {
      return const ManagerSkeletonList(
        padding: EdgeInsets.fromLTRB(MSpace.lg, 0, MSpace.lg, MSpace.lg),
      );
    }
    if (c.error != null && !c.hasLoaded) {
      return centered(ManagerErrorState(error: c.error!, onRetry: c.load));
    }
    final items = c.visible;
    if (items.isEmpty) {
      return centered(
        ManagerEmptyState(
          icon: Icons.inventory_2_outlined,
          title: switch (c.filter) {
            StockFilter.out when c.search.isEmpty => 'Nothing is out of stock',
            StockFilter.low when c.search.isEmpty => 'No low-stock items',
            _ => 'No items found',
          },
          filtered: c.search.isNotEmpty,
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(MSpace.lg, 0, MSpace.lg, MSpace.xxl),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: MSpace.md),
      itemBuilder: (context, i) => StockCard(
        item: items[i],
        lowThreshold: c.lowThreshold,
        onTap: () => _showWarehouses(context, items[i], c.lowThreshold),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : MColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? MColors.navy : MColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? MColors.navy : MColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.item,
    required this.lowThreshold,
    this.onTap,
  });

  final StockItem item;
  final double lowThreshold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final (String status, Color qtyColor) = i.isOutOfStock
        ? ('Out of stock', MColors.red)
        : i.isLow(lowThreshold)
        ? ('Low stock', MColors.orange)
        : ('In stock', MColors.textPrimary);
    final meta = [
      i.itemCode,
      if (i.itemGroup != null) i.itemGroup!,
      if (i.warehouses.length > 1) '${i.warehouses.length} warehouses',
    ].join('  ·  ');

    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: qtyColor == MColors.textPrimary
                  ? MColors.accentSoft
                  : qtyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: qtyColor == MColors.textPrimary
                  ? MColors.accent
                  : qtyColor,
            ),
          ),
          const SizedBox(width: MSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MText.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: MSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _qty(i),
                style: MText.amount.copyWith(fontSize: 15, color: qtyColor),
              ),
              const SizedBox(height: 4),
              StatusChip(status, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

void _showWarehouses(BuildContext context, StockItem item, double threshold) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MSpace.xl,
            0,
            MSpace.xl,
            MSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.displayName,
                style: MText.section.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  item.itemCode,
                  if (item.itemGroup != null) item.itemGroup!,
                ].join('  ·  '),
                style: MText.meta,
              ),
              const SizedBox(height: MSpace.lg),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(MSpace.radiusSm),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Total in stock', style: MText.meta),
                    ),
                    Text(_qty(item), style: MText.amount),
                  ],
                ),
              ),
              const SizedBox(height: MSpace.md),
              const Text('BY WAREHOUSE', style: MText.label),
              const SizedBox(height: 4),
              for (final w in item.warehouses)
                InfoRow(
                  w.warehouse,
                  '${MFormat.qty(w.qty)} ${item.uom}'.trim(),
                  valueColor: w.qty <= 0 ? MColors.red : null,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
