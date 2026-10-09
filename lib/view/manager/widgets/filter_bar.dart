import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/controller/manager/sales_person_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Search box + salesperson / date / status pills + clear action.
/// Every change goes to the controller, which filters on the server.
class ManagerFilterBar<T> extends StatefulWidget {
  const ManagerFilterBar({
    super.key,
    required this.controller,
    required this.searchHint,
    required this.statuses,
    this.statusLabel = 'Status',
  });

  final ManagerListController<T> controller;
  final String searchHint;
  final List<String> statuses;
  final String statusLabel;

  @override
  State<ManagerFilterBar<T>> createState() => _ManagerFilterBarState<T>();
}

class _ManagerFilterBarState<T> extends State<ManagerFilterBar<T>> {
  late final TextEditingController _search;
  late int _seenClear;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.controller.filters.search);
    _seenClear = widget.controller.clearCount;
    widget.controller.addListener(_syncSearch);
  }

  void _syncSearch() {
    if (_seenClear == widget.controller.clearCount) return;
    _seenClear = widget.controller.clearCount;
    _search.clear();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  void _clearAll() => widget.controller.clearFilters();

  Future<void> _pickSalesPerson() async {
    final result = await showModalBottomSheet<_Picked<SalesPerson>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SalesPersonController>(),
        child: _SalesPersonSheet(
          selected: widget.controller.filters.salesPerson,
        ),
      ),
    );
    if (result != null) widget.controller.setSalesPerson(result.value);
  }

  Future<void> _pickDate() async {
    final result = await showModalBottomSheet<_Picked<DateTimeRange>>(
      context: context,
      builder: (_) => _DateSheet(selected: widget.controller.filters.dateRange),
    );
    if (result != null) widget.controller.setDateRange(result.value);
  }

  Future<void> _pickStatus() async {
    final result = await showModalBottomSheet<_Picked<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(
        title: widget.statusLabel,
        statuses: widget.statuses,
        selected: widget.controller.filters.status,
      ),
    );
    if (result != null) widget.controller.setStatus(result.value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final f = widget.controller.filters;
        return Container(
          color: MColors.background,
          padding: const EdgeInsets.fromLTRB(
            MSpace.lg,
            MSpace.sm,
            MSpace.lg,
            MSpace.sm,
          ),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (v) {
                  widget.controller.onSearchChanged(v);
                  setState(() {});
                },
                onSubmitted: widget.controller.submitSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: MColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            widget.controller.submitSearch('');
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: MSpace.sm),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterPill(
                      icon: Icons.person_outline_rounded,
                      label: f.salesPerson?.displayName ?? 'All salespersons',
                      active: f.salesPerson != null,
                      onTap: _pickSalesPerson,
                    ),
                    const SizedBox(width: MSpace.sm),
                    _FilterPill(
                      icon: Icons.calendar_today_rounded,
                      label: f.dateRange == null
                          ? 'Any date'
                          : MFormat.range(f.dateRange!.start, f.dateRange!.end),
                      active: f.dateRange != null,
                      onTap: _pickDate,
                    ),
                    // Status filter only for modules that use one.
                    if (widget.statuses.isNotEmpty) ...[
                      const SizedBox(width: MSpace.sm),
                      _FilterPill(
                        icon: Icons.tune_rounded,
                        label:
                            f.status ??
                            'All ${widget.statusLabel.toLowerCase()}',
                        active: f.status != null,
                        onTap: _pickStatus,
                      ),
                    ],
                    if (f.isActive) ...[
                      const SizedBox(width: MSpace.sm),
                      TextButton.icon(
                        onPressed: _clearAll,
                        style: TextButton.styleFrom(
                          foregroundColor: MColors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text(
                          'Clear',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? MColors.accent : MColors.textSecondary;
    return Material(
      color: active ? MColors.accentSoft : MColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: active
              ? MColors.accent.withValues(alpha: 0.4)
              : MColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a picker result so "All" (null) differs from dismissing the sheet.
class _Picked<V> {
  const _Picked(this.value);
  final V? value;
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(MSpace.xl, 0, MSpace.xl, MSpace.md),
    child: Text(text, style: MText.section.copyWith(fontSize: 17)),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: MSpace.xl),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? MColors.accent : MColors.textPrimary,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!, style: MText.meta),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: MColors.accent,
              size: 20,
            )
          : null,
    );
  }
}

class _SalesPersonSheet extends StatefulWidget {
  const _SalesPersonSheet({required this.selected});
  final SalesPerson? selected;

  @override
  State<_SalesPersonSheet> createState() => _SalesPersonSheetState();
}

class _SalesPersonSheetState extends State<_SalesPersonSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SalesPersonController>().ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesPersonController>();
    final q = _query.toLowerCase();
    final list = ctrl.salesPersons
        .where(
          (s) =>
              q.isEmpty ||
              s.displayName.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Salesperson'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MSpace.xl,
              0,
              MSpace.xl,
              MSpace.sm,
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Search salesperson',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (ctrl.isLoading && ctrl.salesPersons.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.error != null && ctrl.salesPersons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ctrl.error!,
                          style: MText.meta,
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: ctrl.load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  controller: scroll,
                  children: [
                    if (q.isEmpty)
                      _OptionTile(
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: MColors.accentSoft,
                          child: Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: MColors.accent,
                          ),
                        ),
                        title: 'All salespersons',
                        selected: widget.selected == null,
                        onTap: () => Navigator.pop(
                          context,
                          const _Picked<SalesPerson>(null),
                        ),
                      ),
                    for (final s in list)
                      _OptionTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: MColors.greyBg,
                          child: Text(
                            MFormat.initials(s.displayName),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: MColors.textSecondary,
                            ),
                          ),
                        ),
                        title: s.displayName,
                        subtitle: s.displayName != s.name ? s.name : null,
                        selected: widget.selected == s,
                        onTap: () => Navigator.pop(context, _Picked(s)),
                      ),
                    if (list.isEmpty && q.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(MSpace.xxl),
                        child: Text(
                          'No matching salesperson',
                          textAlign: TextAlign.center,
                          style: MText.meta,
                        ),
                      ),
                    const SizedBox(height: MSpace.lg),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSheet extends StatelessWidget {
  const _DateSheet({required this.selected});
  final DateTimeRange? selected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <String, DateTimeRange>{
      'Today': DateTimeRange(start: today, end: today),
      'Yesterday': DateTimeRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      'Last 7 days': DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      'This month': DateTimeRange(
        start: DateTime(now.year, now.month),
        end: today,
      ),
      'Last month': DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
    };
    bool same(DateTimeRange a, DateTimeRange? b) =>
        b != null &&
        DateUtils.isSameDay(a.start, b.start) &&
        DateUtils.isSameDay(a.end, b.end);
    final presetSelected = presets.values.any((r) => same(r, selected));

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetTitle('Date range'),
            _OptionTile(
              title: 'Any date',
              selected: selected == null,
              onTap: () =>
                  Navigator.pop(context, const _Picked<DateTimeRange>(null)),
            ),
            for (final e in presets.entries)
              _OptionTile(
                title: e.key,
                subtitle: MFormat.range(e.value.start, e.value.end),
                selected: same(e.value, selected),
                onTap: () => Navigator.pop(context, _Picked(e.value)),
              ),
            _OptionTile(
              leading: const Icon(
                Icons.date_range_rounded,
                color: MColors.accent,
              ),
              title: 'Custom range…',
              subtitle: selected != null && !presetSelected
                  ? MFormat.range(selected!.start, selected!.end)
                  : null,
              selected: selected != null && !presetSelected,
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(now.year + 1, 12, 31),
                  initialDateRange: selected,
                  helpText: 'Select date range',
                );
                if (picked != null && context.mounted) {
                  Navigator.pop(context, _Picked(picked));
                }
              },
            ),
            const SizedBox(height: MSpace.md),
          ],
        ),
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({
    required this.title,
    required this.statuses,
    required this.selected,
  });

  final String title;
  final List<String> statuses;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetTitle(title),
              _OptionTile(
                title: 'All',
                selected: selected == null,
                onTap: () =>
                    Navigator.pop(context, const _Picked<String>(null)),
              ),
              for (final s in statuses)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: MSpace.xl,
                  ),
                  onTap: () => Navigator.pop(context, _Picked(s)),
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusChip(s),
                  ),
                  trailing: selected == s
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: MColors.accent,
                          size: 20,
                        )
                      : null,
                ),
              const SizedBox(height: MSpace.md),
            ],
          ),
        ),
      ),
    );
  }
}
