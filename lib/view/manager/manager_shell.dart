import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_dashboard_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_leave_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_profile_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_stock_controller.dart';
import 'package:location_tracker_app/controller/manager/sales_person_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/service/manager_leave_service.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/service/manager_stock_service.dart';
import 'package:location_tracker_app/view/manager/dashboard/manager_dashboard.dart';
import 'package:location_tracker_app/view/manager/leaves/leave_list.dart';
import 'package:location_tracker_app/view/manager/stock/stock_list.dart';
import 'package:location_tracker_app/view/manager/sales/sales_hub.dart';
import 'package:location_tracker_app/view/manager/attendance/attendance_list.dart';
import 'package:location_tracker_app/view/manager/visits/visit_list.dart';
import 'package:location_tracker_app/view/manager/widgets/floating_nav_bar.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:provider/provider.dart';

/// Root of the Manager experience. Owns all manager state for the session,
/// so leaving the shell (logout) disposes it.
class ManagerShell extends StatelessWidget {
  const ManagerShell({
    super.key,
    this.service,
    this.leaveService,
    this.stockService,
  });

  /// Injectable for tests; defaults to the live API clients.
  final ManagerService? service;
  final ManagerLeaveService? leaveService;
  final ManagerStockService? stockService;

  @override
  Widget build(BuildContext context) {
    final service = this.service ?? ManagerService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ManagerNavController()),
        ChangeNotifierProvider(
          create: (_) => ManagerProfileController()..ensureLoaded(),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesPersonController(service: service),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerDashboardController(service: service),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerStockController(service: stockService),
        ),
        ChangeNotifierProvider(
          // Loaded up front so the Leaves badge is ready immediately.
          create: (_) =>
              ManagerLeaveController(service: leaveService)..ensureLoaded(),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<AttendanceRecord>(
            fetchPage: service.getAttendance,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<CustomerVisit>(
            fetchPage: service.getCustomerVisits,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<SalesOrderRecord>(
            fetchPage: service.getSalesOrders,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<SalesReturnRecord>(
            fetchPage: service.getSalesReturns,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<SalesInvoiceRecord>(
            fetchPage: service.getSalesInvoices,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagerListController<PaymentEntryRecord>(
            fetchPage: service.getPaymentEntries,
          ),
        ),
      ],
      child: Builder(
        builder: (ctx) =>
            Theme(data: ManagerTheme.of(ctx), child: const _ShellScaffold()),
      ),
    );
  }
}

/// Bottom navigation destinations, in [ManagerTab] order.
List<FloatingNavItem> _navItems({required int pendingLeaves}) => [
  const FloatingNavItem(
    label: 'Home',
    icon: Icons.space_dashboard_outlined,
    activeIcon: Icons.space_dashboard_rounded,
  ),
  const FloatingNavItem(
    label: 'Attendance',
    icon: Icons.how_to_reg_outlined,
    activeIcon: Icons.how_to_reg_rounded,
  ),
  const FloatingNavItem(
    label: 'Visits',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront_rounded,
  ),
  const FloatingNavItem(
    label: 'Sales',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights_rounded,
  ),
  const FloatingNavItem(
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2_rounded,
  ),
  FloatingNavItem(
    label: 'Leaves',
    icon: Icons.event_note_outlined,
    activeIcon: Icons.event_note_rounded,
    badgeCount: pendingLeaves,
  ),
];

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold();

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  /// Tabs are built on first visit and then kept alive, so switching tabs
  /// preserves scroll position, filters and loaded data.
  final Set<ManagerTab> _visited = {ManagerTab.home};

  Widget _page(ManagerTab tab) => switch (tab) {
    ManagerTab.home => const ManagerDashboard(),
    ManagerTab.attendance => const ManagerTabPage(
      title: 'Attendance',
      subtitle: 'Daily check-ins across the team',
      child: AttendanceListView(),
    ),
    ManagerTab.visits => const ManagerTabPage(
      title: 'Customer visits',
      subtitle: 'Field activity logged by salespersons',
      child: VisitListView(),
    ),
    ManagerTab.sales => const ManagerSalesHub(),
    ManagerTab.leaves => const ManagerLeavesScreen(),
    ManagerTab.stock => const ManagerStockScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<ManagerNavController>();
    final pendingLeaves = context.select<ManagerLeaveController, int>(
      (c) => c.pendingCount,
    );
    _visited.add(nav.tab);

    return PopScope(
      // Back from any tab returns Home first; back on Home leaves the app.
      canPop: nav.tab == ManagerTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.goTo(ManagerTab.home);
      },
      child: Scaffold(
        backgroundColor: MColors.background,
        // The bar sits below the body (not over it), so list content is
        // never hidden behind it.
        body: Stack(
          children: [
            for (final tab in ManagerTab.values)
              if (_visited.contains(tab))
                _FadeTab(
                  key: ValueKey(tab),
                  active: nav.tab == tab,
                  child: _page(tab),
                ),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(
          items: _navItems(pendingLeaves: pendingLeaves),
          currentIndex: nav.tab.index,
          onTap: (i) => nav.goTo(ManagerTab.values[i]),
        ),
      ),
    );
  }
}

/// Cross-fades between tabs while keeping every visited tab alive.
/// Hidden tabs ignore touches, are excluded from accessibility and have
/// their animations paused.
class _FadeTab extends StatelessWidget {
  const _FadeTab({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The fade itself must keep ticking; only the page's own animations
    // are paused while hidden.
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.015),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: TickerMode(enabled: active, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
