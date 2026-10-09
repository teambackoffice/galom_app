import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:location_tracker_app/controller/manager/manager_stock_controller.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/service/manager_stock_service.dart';
import 'package:location_tracker_app/view/manager/stock/stock_list.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:provider/provider.dart';

import 'mock_api.dart';

void main() {
  test('rows are grouped per item and summed across warehouses', () async {
    final items = await mockStockService.getStock();
    expect(items.length, 4);
    final oil = items.firstWhere((i) => i.itemCode == 'ITM-001');
    expect(oil.totalQty, 50);
    expect(oil.warehouses.map((w) => w.warehouse), [
      'Stores - GI',
      'Kochi Depot - GI',
    ]);
    expect(items.firstWhere((i) => i.itemCode == 'ITM-004').itemGroup, isNull);
  });

  test('error responses become readable messages', () {
    expect(
      () => ManagerStockService.parse(
        200,
        jsonEncode({
          'message': {'status': 'error', 'message': 'No permission'},
        }),
      ),
      throwsA(
        isA<ManagerApiException>().having(
          (e) => e.message,
          'm',
          'No permission',
        ),
      ),
    );
    expect(
      () => ManagerStockService.parse(403, '{}'),
      throwsA(
        isA<ManagerApiException>()
            .having((e) => e.isSessionExpired, 'not our session', false)
            .having((e) => e.message, 'm', contains('stock server')),
      ),
    );
  });

  test('low / out filters, threshold and name search', () async {
    final c = ManagerStockController(service: mockStockService);
    await c.load();
    // Most urgent first.
    expect(c.visible.first.itemCode, 'ITM-004');
    expect(c.count(StockFilter.out), 2);
    expect(c.count(StockFilter.low), 1);
    c.setFilter(StockFilter.low);
    expect(c.visible.single.itemCode, 'ITM-002');
    c.setLowThreshold(50);
    expect(c.count(StockFilter.low), 2); // oil (50) now counts as low
    c.setFilter(StockFilter.all);
    c.setSearch('rice');
    expect(c.visible.single.itemName, 'Rice 5kg');
    c.setSearch('itm-00');
    expect(c.visible.length, 4);
  });

  testWidgets('stock screen on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ManagerStockController(service: mockStockService);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Theme(
              data: ManagerTheme.of(ctx),
              child: const Scaffold(body: ManagerStockScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('4 items · 1 low · 2 out of stock'), findsOneWidget);
    expect(find.text('Out of stock 2'), findsOneWidget);

    await tester.ensureVisible(find.text('Out of stock 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Out of stock 2'));
    await tester.pumpAndSettle();
    expect(find.text('Soap 100g'), findsNothing);
    expect(find.text('Rice 5kg'), findsOneWidget);

    // Change the low-stock limit.
    c.setFilter(StockFilter.all);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Low ≤ 10'));
    await tester.tap(find.text('Low ≤ 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 or fewer'));
    await tester.pumpAndSettle();
    expect(find.text('4 items · 2 low · 2 out of stock'), findsOneWidget);

    // Warehouse breakdown.
    await tester.ensureVisible(find.textContaining('Coconut Oil'));
    await tester.tap(find.textContaining('Coconut Oil'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('BY WAREHOUSE'), findsOneWidget);
    expect(find.text('Kochi Depot - GI'), findsOneWidget);
  });

  test('calls the metta stock server without the ERP session cookie', () async {
    late Uri uri;
    late Map<String, String> headers;
    final service = ManagerStockService(
      client: MockClient((req) async {
        uri = req.url;
        headers = req.headers;
        return http.Response(
          jsonEncode({
            'message': {'status': 'success', 'data': []},
          }),
          200,
        );
      }),
    );
    await service.getStock();
    expect(
      uri.toString(),
      'https://metta.tbocloud.in/api/method/sales_pilot.Api.auth.get_all_items_stock',
    );
    expect(headers.containsKey('Cookie'), isFalse);
  });
}
