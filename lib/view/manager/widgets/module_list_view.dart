import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/filter_bar.dart';
import 'package:location_tracker_app/view/manager/widgets/state_views.dart';

class SummaryItem {
  const SummaryItem(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

/// Light strip above a list: "Orders 57 | Order value ₹1,25,000".
/// Totals cover every matching row, not only the loaded page.
class SummaryStrip extends StatelessWidget {
  const SummaryStrip({super.key, required this.items});

  final List<SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MSpace.md),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MColors.accentSoft,
        borderRadius: BorderRadius.circular(MSpace.radiusSm),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: MSpace.md),
                color: MColors.accent.withValues(alpha: 0.15),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MText.meta.copyWith(fontSize: 11.5),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      items[i].value,
                      style: MText.amount.copyWith(
                        fontSize: 15,
                        color: items[i].color ?? MColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared list screen body for all six modules: filters, summary, states,
/// pull-to-refresh and infinite scroll.
class ManagerModuleList<T> extends StatefulWidget {
  const ManagerModuleList({
    super.key,
    required this.controller,
    required this.searchHint,
    required this.statuses,
    required this.itemBuilder,
    required this.summaryBuilder,
    this.statusLabel = 'Status',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'No records found',
  });

  final ManagerListController<T> controller;
  final String searchHint;
  final List<String> statuses;
  final String statusLabel;
  final Widget Function(BuildContext context, T record) itemBuilder;
  final List<SummaryItem> Function(ManagerListController<T> c) summaryBuilder;
  final IconData emptyIcon;
  final String emptyTitle;

  @override
  State<ManagerModuleList<T>> createState() => _ManagerModuleListState<T>();
}

class _ManagerModuleListState<T> extends State<ManagerModuleList<T>>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients || widget.controller.loadMoreError != null) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) widget.controller.loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = widget.controller;
    return Column(
      children: [
        ManagerFilterBar<T>(
          controller: c,
          searchHint: widget.searchHint,
          statuses: widget.statuses,
          statusLabel: widget.statusLabel,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) => RefreshIndicator(
              color: MColors.accent,
              onRefresh: c.refresh,
              child: _body(context, c),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scrollableCenter(Widget child) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Center(child: child),
      ),
    ),
  );

  Widget _body(BuildContext context, ManagerListController<T> c) {
    if (c.isLoading && c.records.isEmpty) {
      return const ManagerSkeletonList(
        padding: EdgeInsets.fromLTRB(
          MSpace.lg,
          MSpace.xs,
          MSpace.lg,
          MSpace.lg,
        ),
      );
    }
    if (c.error != null && c.records.isEmpty) {
      return _scrollableCenter(
        ManagerErrorState(error: c.error!, onRetry: c.reload),
      );
    }
    if (c.records.isEmpty) {
      return _scrollableCenter(
        ManagerEmptyState(
          icon: widget.emptyIcon,
          title: widget.emptyTitle,
          filtered: c.filters.isActive,
          onClearFilters: c.clearFilters,
        ),
      );
    }

    final records = c.records;
    if (c.hasMore && !c.isLoadingMore && c.loadMoreError == null) {
      // Fill the viewport when the first page is too short to scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    }
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        MSpace.lg,
        MSpace.xs,
        MSpace.lg,
        MSpace.lg,
      ),
      itemCount: records.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            children: [
              SummaryStrip(items: widget.summaryBuilder(c)),
              if (c.isRefreshing) const LinearProgressIndicator(minHeight: 2),
            ],
          );
        }
        if (i == records.length + 1) {
          return PaginationFooter(
            isLoading: c.isLoadingMore,
            error: c.loadMoreError,
            hasMore: c.hasMore,
            onRetry: c.loadMore,
            shown: records.length,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: MSpace.md),
          child: widget.itemBuilder(context, records[i - 1]),
        );
      },
    );
  }
}

/// Standard count summary item.
SummaryItem countItem(int n, [String label = 'Records']) =>
    SummaryItem(label, MFormat.count(n));
