// Shared mocked Manager API responses for tests.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:location_tracker_app/service/manager_leave_service.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/service/manager_stock_service.dart';

const _cust =
    'Sree Vadakkumnathan Wholesale Distributors and Traders Private Limited';

http.Response _ok(Object data) => http.Response(
  jsonEncode({'message': 'ok', 'data': data, 'success': true}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _list(
  List<Map<String, Object?>> rows,
  Map<String, num> totals,
) => {
  'records': rows,
  'total_count': 1234,
  'start': 0,
  'page_length': 5,
  'has_more': true,
  'totals': totals,
};

final mockService = ManagerService(
  readSid: () async => 'test',
  client: MockClient((req) async {
    final method = req.url.pathSegments.last.split('.').last;
    switch (method) {
      case 'get_attendance':
        return _ok(
          _list([
            {
              'employee': 'E1',
              'sales_person_name': 'Anu K',
              'attendance_date': '2026-10-09',
              'check_in': '2026-10-09 09:05:00',
              'status': 'Checked In',
              'log_count': 1,
            },
          ], {}),
        );
      case 'get_customer_visits':
        return _ok(
          _list([
            {
              'name': 'CV-1',
              'sales_person_name': 'Biju M',
              'date': '2026-10-09',
              'time': '11:00:00',
              'customer_name': _cust,
            },
          ], {}),
        );
      case 'get_sales_orders':
        return _ok(
          _list(
            [
              {
                'name': 'SO-1',
                'customer_name': _cust,
                'transaction_date': '2026-10-09',
                'grand_total': 1000,
                'status': 'To Bill',
              },
            ],
            {'grand_total': 12345678.5},
          ),
        );
      case 'get_sales_returns':
        return _ok(_list([], {'grand_total': -2500}));
      case 'get_sales_invoices':
        return http.Response(
          jsonEncode({
            'message': 'Server error',
            'data': null,
            'success': false,
          }),
          500,
        );
      case 'get_payment_entries':
        return _ok(
          _list(
            [
              {
                'name': 'PE-1',
                'customer_name': _cust,
                'posting_date': '2026-10-08',
                'paid_amount': 600,
                'status': 'Submitted',
              },
            ],
            {'paid_amount': 98765.4},
          ),
        );
      case 'get_transaction_detail':
        return _ok({
          'doctype': 'Sales Invoice',
          'name': 'ACC-SINV-2026-00120',
          'status': 'Partly Paid',
          'docstatus': 1,
          'company': 'Galom International Pvt Ltd',
          'currency': 'INR',
          'sales_person': 'Anu',
          'sales_person_name': 'Anu K',
          'owner': 'anu@example.com',
          'creation': '2026-10-02 10:00:00.000000',
          'customer': 'CA-CUS-02064',
          'customer_name': _cust,
          'posting_date': '2026-10-02',
          'due_date': '2026-10-12',
          'is_return': 0,
          'return_against': null,
          'return_reason': '',
          'total': 900,
          'total_taxes_and_charges': 100,
          'grand_total': 1000,
          'rounded_total': 1000,
          'outstanding_amount': 400,
          'payment_status': 'Partly Paid',
          'items': [
            {
              'item_code': 'ITM-001',
              'item_name': 'Soap 100g extra long product description name',
              'qty': 10,
              'uom': 'Nos',
              'rate': 90,
              'amount': 900,
            },
          ],
          'taxes': [
            {'description': 'CGST', 'rate': 9, 'tax_amount': 50},
          ],
          'sales_team': [
            {
              'sales_person': 'Anu',
              'allocated_percentage': 100,
              'sales_person_name': 'Anu K',
            },
          ],
          'payments': [
            {
              'payment_entry': 'ACC-PAY-2026-00310',
              'posting_date': '2026-10-03',
              'mode_of_payment': 'Cash',
              'allocated_amount': 600,
              'status': 'Submitted',
            },
          ],
          'returns': [
            {
              'name': 'ACC-SINV-RET-2026-00007',
              'posting_date': '2026-10-04',
              'grand_total': -100,
            },
          ],
        });
      case 'get_attendance_detail':
        return _ok({
          'employee': 'HR-EMP-00001',
          'employee_name': 'Anu',
          'sales_person': 'Anu',
          'date': '2026-10-01',
          'logs': [
            {
              'log_type': 'IN',
              'time': '2026-10-01 09:05:00',
              'device_id': 'mobile_app',
              'latitude': 10.1234,
              'longitude': 76.2345,
              'location_name': '',
            },
            {
              'log_type': 'OUT',
              'time': '2026-10-01 18:10:00',
              'device_id': '',
              'latitude': 0.000001,
              'longitude': 0.000001,
              'location_name': '',
            },
          ],
          'attendance': {
            'name': 'HR-ATT-2026-00012',
            'status': 'Present',
            'working_hours': 9.08,
          },
        });
    }
    return http.Response('{}', 404);
  }),
);

final mockLeaveService = ManagerLeaveService(
  readSid: () async => 'test',
  client: MockClient(
    (req) async => http.Response(
      jsonEncode({
        'message': {
          'status': 'success',
          'applications': [
            {
              'name': 'HR-LAP-1',
              'employee_name': 'Anu',
              'leave_type': 'Casual Leave',
              'from_date': '2026-10-12',
              'to_date': '2026-10-13',
              'total_leave_days': 2,
              'status': 'Open',
              'docstatus': 0,
            },
            {
              'name': 'HR-LAP-2',
              'employee_name': 'Biju',
              'leave_type': 'Sick Leave',
              'from_date': '2026-10-01',
              'to_date': '2026-10-01',
              'total_leave_days': 1,
              'status': 'Approved',
              'docstatus': 1,
            },
          ],
        },
      }),
      200,
    ),
  ),
);

/// Stock rows (one per item + warehouse): 1 in stock across 2 warehouses,
/// 1 low (qty 4), 2 out of stock (0 and negative).
final mockStockService = ManagerStockService(
  client: MockClient(
    (req) async => http.Response(
      jsonEncode({
        'message': {
          'status': 'success',
          'message': 'ok',
          'code': 200,
          'data': [
            {
              'item_code': 'ITM-001',
              'item_name': 'Coconut Oil 1L Premium Cold Pressed Family Pack',
              'stock_uom': 'Nos',
              'item_group': 'Oils',
              'warehouse': 'Stores - GI',
              'actual_qty': 30,
            },
            {
              'item_code': 'ITM-001',
              'item_name': 'Coconut Oil 1L Premium Cold Pressed Family Pack',
              'stock_uom': 'Nos',
              'item_group': 'Oils',
              'warehouse': 'Kochi Depot - GI',
              'actual_qty': 20,
            },
            {
              'item_code': 'ITM-002',
              'item_name': 'Soap 100g',
              'stock_uom': 'Nos',
              'item_group': 'Soaps',
              'warehouse': 'Stores - GI',
              'actual_qty': 4,
            },
            {
              'item_code': 'ITM-003',
              'item_name': 'Rice 5kg',
              'stock_uom': 'Bag',
              'item_group': 'Grains',
              'warehouse': 'Stores - GI',
              'actual_qty': 0,
            },
            {
              'item_code': 'ITM-004',
              'item_name': 'Tea Powder 250g',
              'stock_uom': 'Nos',
              'item_group': null,
              'warehouse': 'Stores - GI',
              'actual_qty': -2,
            },
          ],
        },
      }),
      200,
    ),
  ),
);
