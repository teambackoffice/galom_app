import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:provider/provider.dart';

class ManagerTabSpec {
  const ManagerTabSpec(this.label, this.child);
  final String label;
  final Widget child;
}

/// Title + tab bar + pages, kept in sync with [ManagerNavController] so the
/// dashboard can open a specific sub-tab.
class ManagerTabbedPage extends StatefulWidget {
  const ManagerTabbedPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.tabs,
    required this.indexOf,
    required this.onIndex,
  });

  final String title;
  final String? subtitle;
  final List<ManagerTabSpec> tabs;
  final int Function(ManagerNavController nav) indexOf;
  final void Function(ManagerNavController nav, int index) onIndex;

  @override
  State<ManagerTabbedPage> createState() => _ManagerTabbedPageState();
}

class _ManagerTabbedPageState extends State<ManagerTabbedPage>
    with SingleTickerProviderStateMixin {
  late final ManagerNavController _nav = context.read<ManagerNavController>();
  late final TabController _tabs = TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.indexOf(_nav),
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
    _nav.addListener(_onNavChanged);
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) widget.onIndex(_nav, _tabs.index);
  }

  void _onNavChanged() {
    final i = widget.indexOf(_nav);
    if (_tabs.index != i) _tabs.animateTo(i);
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavChanged);
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagerTabHeader(title: widget.title, subtitle: widget.subtitle),
          // Pill-style segmented tabs, matching the navigation bar.
          SizedBox(
            height: 48,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.fromLTRB(MSpace.lg, 4, MSpace.lg, 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: MColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              splashBorderRadius: BorderRadius.circular(12),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: MColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                for (final t in widget.tabs) Tab(height: 40, text: t.label),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [for (final t in widget.tabs) t.child],
            ),
          ),
        ],
      ),
    );
  }
}
