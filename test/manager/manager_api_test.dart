import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_detail_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

void main() {
  group('envelope', () {
    test('success only when 200 and success == true', () {
      final data = ManagerService.parseEnvelope(
        200,
        jsonEncode({
          'message': 'ok',
          'data': {'x': 1},
          'success': true,
        }),
      );
      expect(data['x'], 1);
      expect(
        () => ManagerService.parseEnvelope(
          200,
          jsonEncode({'message': 'no', 'data': null, 'success': false}),
        ),
        throwsA(
          isA<ManagerApiException>().having((e) => e.message, 'message', 'no'),
        ),
      );
    });

    test('403 with envelope = not a manager', () {
      expect(
        () => ManagerService.parseEnvelope(
          403,
          jsonEncode({
            'message': 'Only managers can view team records',
            'data': null,
            'success': false,
          }),
        ),
        throwsA(
          isA<ManagerApiException>()
              .having((e) => e.isForbidden, 'forbidden', true)
              .having((e) => e.isSessionExpired, 'expired', false)
              .having(
                (e) => e.message,
                'message',
                'Only managers can view team records',
              ),
        ),
      );
    });

    test('Frappe 401/403 without envelope = session expired', () {
      for (final code in [401, 403]) {
        expect(
          () => ManagerService.parseEnvelope(
            code,
            jsonEncode({
              'exc_type': 'PermissionError',
              '_server_messages': '[]',
            }),
          ),
          throwsA(
            isA<ManagerApiException>()
                .having((e) => e.isSessionExpired, 'expired', true)
                .having(
                  (e) => e.message,
                  'message',
                  ManagerService.sessionExpiredMessage,
                ),
          ),
        );
      }
    });

    test('malformed body and 500 map to readable messages', () {
      expect(
        () => ManagerService.parseEnvelope(500, '<html>oops</html>'),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.message,
            'm',
            'Server error. Please try again.',
          ),
        ),
      );
      expect(
        () => ManagerService.parseEnvelope(200, 'not json'),
        throwsA(isA<ManagerApiException>()),
      );
      expect(
        () => ManagerService.parseEnvelope(
          400,
          jsonEncode({'message': 'from_date after to_date', 'success': false}),
        ),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.message,
            'm',
            'from_date after to_date',
          ),
        ),
      );
    });
  });

  group('service requests', () {
    test('sends cookie, encodes doctype, and builds common params', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'message': 'Sales orders',
            'data': {
              'records': [
                {
                  'name': 'SO-1',
                  'grand_total': 1000,
                  'sales_person': null,
                  'sales_person_name': '',
                },
              ],
              'total_count': 57,
              'start': 0,
              'page_length': 20,
              'has_more': true,
              'totals': {'grand_total': 125000},
            },
            'success': true,
          }),
          200,
        );
      });
      final service = ManagerService(
        client: client,
        readSid: () async => 'abc',
        baseUrl: 'https://x/api/method/m.',
      );
      final page = await service.getSalesOrders(
        ManagerQuery(
          salesPerson: 'Anu',
          dateRange: DateTimeRange(
            start: DateTime(2026, 10, 1),
            end: DateTime(2026, 10, 31),
          ),
          search: '  alpha ',
          status: 'To Bill',
          start: 20,
          pageLength: 500,
        ),
      );
      expect(captured.headers['Cookie'], 'sid=abc');
      expect(captured.url.path, '/api/method/m.get_sales_orders');
      expect(captured.url.queryParameters, {
        'start': '20',
        'page_length': '100',
        'sales_person': 'Anu',
        'from_date': '2026-10-01',
        'to_date': '2026-10-31',
        'search': 'alpha',
        'status': 'To Bill',
      });
      expect(page.totalCount, 57);
      expect(page.hasMore, true);
      expect(page.totals['grand_total'], 125000.0);
      expect(page.records.single.grandTotal, 1000.0);
      expect(page.records.single.salesPersonDisplay, 'Unassigned');

      await service.getTransactionDetail(doctype: 'Sales Order', name: 'SO-1');
      expect(captured.url.toString(), contains('doctype=Sales+Order'));
    });

    test('missing sid fails as session expired without a request', () async {
      var called = false;
      final service = ManagerService(
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
        readSid: () async => null,
      );
      await expectLater(
        service.getManagerAccess(),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.isSessionExpired,
            'expired',
            true,
          ),
        ),
      );
      expect(called, false);
    });

    test('network failure maps to a connection message', () async {
      final service = ManagerService(
        client: MockClient((_) async => throw http.ClientException('down')),
        readSid: () async => 's',
      );
      await expectLater(
        service.getSalesPersons(),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.message,
            'm',
            contains('internet'),
          ),
        ),
      );
    });
  });

  group('parsing', () {
    test('attendance row with nulls', () {
      final r = AttendanceRecord.fromJson({
        'employee': 'HR-EMP-00002',
        'employee_name': 'Biju',
        'sales_person': 'Biju',
        'sales_person_name': 'Biju M',
        'attendance_date': '2026-10-02',
        'check_in': null,
        'check_out': null,
        'log_count': 0,
        'attendance': 'HR-ATT-2026-00013',
        'attendance_status': 'Absent',
        'status': 'Absent',
      });
      expect(r.displayName, 'Biju M');
      expect(r.checkIn, isNull);
      expect(r.attendanceDate, DateTime(2026, 10, 2));
      expect(r.rawDate, '2026-10-02');
    });

    test(
      'visit time without leading zero and microseconds; GPS placeholders',
      () {
        final v = CustomerVisit.fromJson({
          'name': 'CV-1',
          'date': '2026-10-03',
          'time': '9:05:00.123456',
          'customer_name': 'Gamma',
          'description': null,
          'latitude': 0.000001,
          'longitude': 76.4,
          'creation': '2026-10-03 17:00:12.345678',
          'is_first_counter': 1,
          'is_last_counter': 0,
          'visit_photo': null,
          'visit_type': '',
        });
        expect(v.visitedAt, DateTime(2026, 10, 3, 9, 5));
        expect(v.locationName, isNull);
        expect(
          CustomerVisit.fromJson({
            'location_name': ' MG Road, Kochi ',
          }).locationName,
          'MG Road, Kochi',
        );
        expect(v.remarks, '');
        expect(v.hasLocation, false);
        expect(v.isFirstCounter, true);
        expect(v.creation, isNotNull);
        expect(combineDateAndTime(DateTime(2026), 'garbage'), isNull);
      },
    );

    test(
      'returns keep negative amounts; invoices fall back payment_status',
      () {
        final r = SalesReturnRecord.fromJson({
          'name': 'RET',
          'grand_total': -100,
          'return_against': null,
        });
        expect(r.grandTotal, -100.0);
        expect(r.returnAgainst, isNull);
        final i = SalesInvoiceRecord.fromJson({
          'name': 'INV',
          'status': 'Draft',
          'outstanding_amount': '400.5',
        });
        expect(i.paymentStatus, 'Draft');
        expect(i.outstandingAmount, 400.5);
      },
    );

    test('payment entry linked invoices and wrong types', () {
      final p = PaymentEntryRecord.fromJson({
        'name': 'PE',
        'paid_amount': 600,
        'linked_invoices': ['A', null, '', 'B'],
        'reference_no': null,
        'docstatus': '1',
      });
      expect(p.linkedInvoices, ['A', 'B']);
      expect(p.docstatus, 1);
      expect(p.referenceNo, isNull);
    });

    test('attendance detail and transaction detail', () {
      final d = AttendanceDetail.fromJson({
        'employee': 'E1',
        'date': '2026-10-01',
        'logs': [
          {
            'log_type': 'in',
            'time': '2026-10-01 09:05:00',
            'latitude': null,
            'longitude': null,
            'device_id': '',
          },
        ],
        'attendance': null,
      });
      expect(d.logs.single.isIn, true);
      expect(d.logs.single.hasLocation, false);
      expect(d.logs.single.deviceId, isNull);
      expect(d.attendance, isNull);

      final t = TransactionDetail.fromJson({
        'doctype': 'Sales Invoice',
        'name': 'INV',
        'is_return': 1,
        'return_against': 'INV-0',
        'items': [
          {'item_code': 'I', 'qty': -1, 'rate': 10, 'amount': -10},
        ],
        'payments': [],
        'references': 'oops',
      });
      expect(t.isSalesInvoice, true);
      expect(t.isReturn, true);
      expect(t.items.single.qty, -1.0);
      expect(t.references, isEmpty);
      expect(t.grandTotal, isNull);
    });
  });
}
