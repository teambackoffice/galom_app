import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:location_tracker_app/controller/manager/manager_leave_controller.dart';
import 'package:location_tracker_app/service/manager_leave_service.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/leaves/leave_list.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:provider/provider.dart';

const _longName = 'Anu Krishnan Nair Valiyaveettil Puthenpurayil';

Map<String, Object?> _leave(String name, String status, {int docstatus = 0}) =>
    {
      'name': name,
      'employee': 'HR-EMP-0001',
      'employee_name': name == 'L1' ? _longName : 'Biju M',
      'leave_type': name == 'L1'
          ? 'Compensatory Off Leave Without Pay'
          : 'Sick Leave',
      'from_date': '2026-10-12',
      'to_date': name == 'L1' ? '2026-10-14' : '2026-10-12',
      'half_day': name == 'L2' ? 1 : 0,
      'total_leave_days': name == 'L2' ? 0.5 : 3,
      'description': 'Family function in hometown, will be reachable on phone',
      'leave_balance': 8,
      'status': status,
      'docstatus': docstatus,
    };

class _Fake {
  final requests = <http.Request>[];
  String approveBody = jsonEncode({
    'message': {'status': 'success'},
  });
  int approveCode = 200;

  late final service = ManagerLeaveService(
    readSid: () async => 'sid',
    client: MockClient((req) async {
      requests.add(req);
      if (req.url.path.endsWith('get_leave_application')) {
        return http.Response(
          jsonEncode({
            'message': {
              'status': 'success',
              'applications': [
                _leave('L3', 'Approved', docstatus: 1),
                _leave('L1', 'Open'),
                _leave('L2', 'Open'),
                _leave('L4', 'Rejected', docstatus: 1),
              ],
            },
          }),
          200,
        );
      }
      return http.Response(approveBody, approveCode);
    }),
  );
}

void main() {
  group('ManagerLeaveService.parseResponse', () {
    test('error status inside message', () {
      expect(
        () => ManagerLeaveService.parseResponse(
          200,
          jsonEncode({
            'message': {'status': 'error', 'message': 'Not allowed'},
          }),
        ),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.message,
            'm',
            'Not allowed',
          ),
        ),
      );
    });

    test('Frappe permission error reads _server_messages', () {
      final body = jsonEncode({
        'exc_type': 'PermissionError',
        '_server_messages': jsonEncode([
          jsonEncode({'message': 'Only the <b>Leave Approver</b> can approve'}),
        ]),
      });
      expect(
        () => ManagerLeaveService.parseResponse(403, body),
        throwsA(
          isA<ManagerApiException>()
              .having(
                (e) => e.message,
                'm',
                'Only the Leave Approver can approve',
              )
              .having((e) => e.isSessionExpired, 'expired', false),
        ),
      );
      expect(
        () => ManagerLeaveService.parseResponse(401, '{}'),
        throwsA(
          isA<ManagerApiException>().having(
            (e) => e.isSessionExpired,
            'expired',
            true,
          ),
        ),
      );
    });
  });

  group('ManagerLeaveController', () {
    test('sorts pending first, filters and counts', () async {
      final c = ManagerLeaveController(service: _Fake().service);
      await c.load();
      expect(c.pendingCount, 2);
      expect(c.visible.map((l) => l.name), ['L1', 'L2']);
      c.setFilter(LeaveFilter.all);
      expect(c.visible.first.isPending, true);
      expect(c.count(LeaveFilter.approved), 1);
      c.setSearch('sick');
      expect(c.visible.map((l) => l.name), ['L2', 'L3', 'L4']);
    });

    test('approve posts docname and updates status locally', () async {
      final fake = _Fake();
      final c = ManagerLeaveController(service: fake.service);
      await c.load();
      final err = await c.approve(c.byName('L1')!);
      expect(err, isNull);
      final req = fake.requests.last;
      expect(req.method, 'POST');
      expect(req.url.path, endsWith('approve_leave_application'));
      expect(req.url.queryParameters['docname'], 'L1');
      expect(req.headers['Cookie'], 'sid=sid');
      expect(c.byName('L1')!.status, 'Approved');
      expect(c.pendingCount, 1);
    });

    test('reject failure keeps status and returns message', () async {
      final fake = _Fake()
        ..approveCode = 417
        ..approveBody = jsonEncode({'message': 'Leave balance insufficient'});
      final c = ManagerLeaveController(service: fake.service);
      await c.load();
      final err = await c.reject(c.byName('L2')!);
      expect(err, 'Leave balance insufficient');
      expect(c.byName('L2')!.isPending, true);
    });
  });

  testWidgets('leave screen on a 320px phone: approve flow', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ManagerLeaveController(service: _Fake().service);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Theme(
              data: ManagerTheme.of(ctx),
              child: const Scaffold(body: ManagerLeavesScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Pending 2'), findsOneWidget);
    expect(find.text('Approve'), findsNWidgets(2));
    expect(find.textContaining('0.5 days (half day)'), findsOneWidget);

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    expect(find.text('Approve leave?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pumpAndSettle();
    expect(find.text('Leave approved'), findsOneWidget);
    expect(find.text('Pending 1'), findsOneWidget);

    // Detail sheet
    await tester.tap(find.text('Biju M'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('REASON'), findsOneWidget);
    expect(find.text('Balance before leave'), findsOneWidget);
  });
}
