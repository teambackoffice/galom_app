import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/controller/manager/sales_person_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/attendance/attendance_list.dart';
import 'package:location_tracker_app/view/manager/sales/sales_cards.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/visits/visit_detail.dart';
import 'package:location_tracker_app/view/manager/visits/visit_list.dart';
import 'package:location_tracker_app/view/manager/widgets/module_list_view.dart';
import 'package:provider/provider.dart';

Widget _host(Widget child) => ChangeNotifierProvider(
  create: (_) => SalesPersonController(),
  child: MaterialApp(
    home: Builder(
      builder: (ctx) => Theme(
        data: ManagerTheme.of(ctx),
        child: Scaffold(body: child),
      ),
    ),
  ),
);

const _longName =
    'Sree Vadakkumnathan Wholesale Distributors and Traders Private Limited';

void main() {
  testWidgets('cards render without overflow on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SalesOrderCard(
              order: SalesOrderRecord.fromJson({
                'name': 'SAL-ORD-2026-00045',
                'customer_name': _longName,
                'grand_total': 12345678.9,
                'status': 'To Deliver and Bill',
                'docstatus': 1,
                'per_delivered': 40,
                'per_billed': 0,
                'sales_person_name': 'Anu K',
                'transaction_date': '2026-10-01',
                'delivery_date': '2026-10-05',
              }),
            ),
            SalesReturnCard(
              salesReturn: SalesReturnRecord.fromJson({
                'name': 'ACC-SINV-RET-2026-00007',
                'customer_name': _longName,
                'grand_total': -100,
                'status': 'Return',
                'return_against': 'ACC-SINV-2026-00120',
                'return_reason': 'Damaged',
              }),
            ),
            SalesInvoiceCard(
              invoice: SalesInvoiceRecord.fromJson({
                'name': 'ACC-SINV-2026-00120',
                'customer_name': _longName,
                'grand_total': 9876543.21,
                'outstanding_amount': 400,
                'status': 'Overdue',
                'payment_status': 'Partly Paid',
                'docstatus': 1,
                'due_date': '2026-10-12',
              }),
            ),
            PaymentEntryCard(
              payment: PaymentEntryRecord.fromJson({
                'name': 'ACC-PAY-2026-00310',
                'customer_name': _longName,
                'paid_amount': 600,
                'mode_of_payment': 'Bank Transfer',
                'reference_no': 'UTR123456789012',
                'status': 'Submitted',
                'docstatus': 1,
                'linked_invoices': [
                  'ACC-SINV-2026-00120',
                  'ACC-SINV-2026-00121',
                  'ACC-SINV-2026-00122',
                ],
              }),
            ),
            AttendanceCard(
              record: AttendanceRecord.fromJson({
                'employee': 'HR-EMP-00001',
                'sales_person_name': 'Anu Krishnan Nair Valiyaveettil',
                'attendance_date': '2026-10-01',
                'check_in': '2026-10-01 09:05:00',
                'check_out': null,
                'log_count': 1,
                'status': 'Checked Out (no check-in)',
                'attendance_status': 'Half Day',
              }),
            ),
            VisitCard(
              visit: CustomerVisit.fromJson({
                'name': 'CV-003',
                'sales_person_name': 'Biju M',
                'date': '2026-10-03',
                'time': '17:00:00',
                'customer_name': _longName,
                'description': 'Collected cheque, next visit Monday ' * 5,
                'is_first_counter': 1,
                'is_last_counter': 1,
                'visit_photo': '/private/files/x.jpg',
                'visit_type': 'Customer Visit',
                'location_name':
                    'Opposite Lulu Mall, Edappally, Kochi, Ernakulam District, Kerala 682024',
              }),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('-₹100.00'), findsOneWidget);
    expect(find.text('3 invoices'), findsOneWidget);
    expect(find.text('First Counter'), findsOneWidget);
    expect(find.textContaining('Opposite Lulu Mall'), findsOneWidget);
  });

  testWidgets('module list shows summary totals, rows and end marker', (
    tester,
  ) async {
    final c = ManagerListController<SalesInvoiceRecord>(
      fetchPage: (q) async => ManagerPage(
        records: [
          SalesInvoiceRecord.fromJson({
            'name': 'INV-1',
            'customer_name': 'Alpha',
            'grand_total': 1000,
            'outstanding_amount': 400,
          }),
        ],
        totalCount: 1,
        start: 0,
        pageLength: 20,
        hasMore: false,
        totals: {'grand_total': 1000.0, 'outstanding_amount': 400.0},
      ),
    );
    await tester.pumpWidget(
      _host(
        ManagerModuleList<SalesInvoiceRecord>(
          controller: c,
          searchHint: 'Search',
          statuses: ManagerModule.salesInvoices.statuses,
          summaryBuilder: (c) => [
            countItem(c.totalCount, 'Invoices'),
            SummaryItem('Outstanding', '₹${c.totals['outstanding_amount']}'),
          ],
          itemBuilder: (_, r) => SalesInvoiceCard(invoice: r),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('INV-1'), findsOneWidget);
    expect(find.text('₹400.0'), findsOneWidget);
    expect(find.text('Showing all 1'), findsOneWidget);
    expect(find.text('All salespersons'), findsOneWidget);
  });

  testWidgets('empty filtered list offers Clear filters; error offers Retry', (
    tester,
  ) async {
    var fail = false;
    final c = ManagerListController<SalesOrderRecord>(
      fetchPage: (q) async {
        if (fail) {
          throw const ManagerApiException(
            'Server error. Please try again.',
            statusCode: 500,
          );
        }
        return const ManagerPage(
          records: [],
          totalCount: 0,
          start: 0,
          pageLength: 20,
          hasMore: false,
          totals: {},
        );
      },
    );
    await tester.pumpWidget(
      _host(
        ManagerModuleList<SalesOrderRecord>(
          controller: c,
          searchHint: 'Search',
          statuses: ManagerModule.salesOrders.statuses,
          summaryBuilder: (c) => [countItem(c.totalCount)],
          itemBuilder: (_, r) => SalesOrderCard(order: r),
        ),
      ),
    );
    await tester.pumpAndSettle();
    c.setStatus('Completed');
    await tester.pumpAndSettle();
    expect(find.text('No records found'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(c.filters.isActive, false);

    fail = true;
    await c.reload();
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('visit detail shows location_name on a 320px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final visit = CustomerVisit.fromJson({
      'name': 'CV-9',
      'sales_person_name': 'Biju M',
      'date': '2026-10-03',
      'time': '17:00:00',
      'customer_name': 'Gamma Traders',
      'latitude': 10.0261,
      'longitude': 76.3125,
      'location_name':
          'Opposite Lulu Mall, Edappally, Kochi, Ernakulam District, Kerala 682024',
    });
    await tester.pumpWidget(_host(ManagerVisitDetailScreen(visit: visit)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Place'), findsOneWidget);
    // Header + Location section both show it.
    expect(find.textContaining('Opposite Lulu Mall'), findsNWidgets(2));
    expect(
      find.text('Location was not captured for this visit.'),
      findsNothing,
    );
  });
}
