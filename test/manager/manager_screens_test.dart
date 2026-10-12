import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracker_app/controller/manager/manager_dashboard_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_leave_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_profile_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_stock_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/view/manager/attendance/attendance_detail.dart';
import 'package:location_tracker_app/view/manager/dashboard/manager_dashboard.dart';
import 'package:location_tracker_app/view/manager/sales/transaction_detail.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:provider/provider.dart';

import 'mock_api.dart';

void _narrow(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _themed(Widget child) => MaterialApp(
  home: Builder(
    builder: (ctx) => Theme(data: ManagerTheme.of(ctx), child: child),
  ),
);

void main() {
  test('compact money formatting', () {
    expect(MFormat.moneyCompact(98765.4), '₹98,765');
    expect(MFormat.moneyCompact(12345678.5), isNot(contains('12345678')));
    expect(MFormat.money(-100), '-₹100.00');
  });

  testWidgets('dashboard loads per-module and isolates a failing module', (
    tester,
  ) async {
    _narrow(tester);
    final dash = ManagerDashboardController(
      service: mockService,
      clock: () => DateTime(2026, 10, 9, 10),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dash),
          ChangeNotifierProvider(create: (_) => ManagerNavController()),
          ChangeNotifierProvider(create: (_) => ManagerProfileController()),
          ChangeNotifierProvider(
            create: (_) => ManagerLeaveController(service: mockLeaveService),
          ),
          ChangeNotifierProvider(
            create: (_) => ManagerStockController(service: mockStockService),
          ),
        ],
        child: _themed(const Scaffold(body: ManagerDashboard())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sales Team Overview'), findsOneWidget);
    expect(find.text('1 leave request'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    // Invoices failed; others still show data.
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('₹98,765.40'), findsOneWidget);
    expect(find.text('Leave Requests'), findsOneWidget);
    // Stock shortcut shows low / out-of-stock counts; no activity feed.
    expect(find.text('Recent activity'), findsNothing);
    expect(find.text('1 low · 2 out'), findsOneWidget);
  });

  testWidgets('invoice detail renders all sections on a narrow phone', (
    tester,
  ) async {
    _narrow(tester);
    await tester.pumpWidget(
      _themed(
        ManagerTransactionDetailScreen(
          doctype: 'Sales Invoice',
          name: 'ACC-SINV-2026-00120',
          service: mockService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Invoice total'), findsOneWidget);
    for (final label in [
      'Payments received',
      'Returns against this invoice',
      'Sales team',
    ]) {
      await tester.dragUntilVisible(
        find.text(label),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('attendance detail hides placeholder GPS', (tester) async {
    _narrow(tester);
    await tester.pumpWidget(
      _themed(
        ManagerAttendanceDetailScreen(
          service: mockService,
          record: AttendanceRecord.fromJson({
            'employee': 'HR-EMP-00001',
            'sales_person_name': 'Anu K',
            'attendance_date': '2026-10-01',
            'check_in': '2026-10-01 09:05:00',
            'check_out': '2026-10-01 18:10:00',
            'status': 'Checked Out',
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('9h 05m'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Location not captured'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.textContaining('10.12340'), findsOneWidget);
    expect(find.text('Location not captured'), findsOneWidget);
  });
}
