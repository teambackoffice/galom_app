import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracker_app/controller/manager/manager_dashboard_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

ManagerPage<int> _page(
  List<int> rows, {
  required int total,
  required bool more,
}) => ManagerPage(
  records: rows,
  totalCount: total,
  start: 0,
  pageLength: 20,
  hasMore: more,
  totals: {'grand_total': total * 10.0},
);

void main() {
  group('ManagerListController', () {
    test('first load, then appends with start = records.length', () async {
      final queries = <ManagerQuery>[];
      final c = ManagerListController<int>(
        pageLength: 2,
        fetchPage: (q) async {
          queries.add(q);
          return q.start == 0
              ? _page([1, 2], total: 3, more: true)
              : _page([3], total: 3, more: false);
        },
      );
      await c.reload();
      expect(c.records, [1, 2]);
      expect(c.hasMore, true);
      await c.loadMore();
      expect(c.records, [1, 2, 3]);
      expect(c.hasMore, false);
      expect(queries.map((q) => q.start), [0, 2]);
      await c.loadMore(); // no-op once has_more is false
      expect(queries.length, 2);
      expect(c.totals['grand_total'], 30);
    });

    test(
      'filter change resets to start=0 and ignores stale responses',
      () async {
        final slow = Completer<ManagerPage<int>>();
        var calls = 0;
        final c = ManagerListController<int>(
          fetchPage: (q) {
            calls++;
            if (calls == 1) return slow.future; // initial, slow
            expect(q.start, 0);
            expect(q.status, 'Paid');
            return Future.value(_page([9], total: 1, more: false));
          },
        );
        final first = c.reload();
        c.setStatus('Paid');
        await Future<void>.delayed(Duration.zero);
        slow.complete(_page([1, 2, 3], total: 3, more: true)); // arrives late
        await first;
        expect(c.records, [9]);
        expect(c.filters.status, 'Paid');
      },
    );

    test('search is debounced and trimmed', () async {
      final searches = <String?>[];
      final c = ManagerListController<int>(
        searchDebounce: const Duration(milliseconds: 30),
        fetchPage: (q) async {
          searches.add(q.search);
          return _page([], total: 0, more: false);
        },
      );
      c.onSearchChanged('a');
      c.onSearchChanged('al');
      c.onSearchChanged(' alpha ');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(searches, ['alpha']);
      expect(c.filters.isActive, true);
      c.clearFilters();
      await Future<void>.delayed(Duration.zero);
      expect(c.filters.isActive, false);
      expect(c.clearCount, 1);
    });

    test('errors: initial error state, load-more error keeps rows', () async {
      var fail = true;
      final c = ManagerListController<int>(
        fetchPage: (q) async {
          if (q.start == 0 && fail) {
            throw const ManagerApiException('boom', statusCode: 500);
          }
          if (q.start > 0) throw const ManagerApiException('page failed');
          return _page([1], total: 2, more: true);
        },
      );
      await c.reload();
      expect(c.error?.message, 'boom');
      expect(c.records, isEmpty);
      fail = false;
      await c.reload();
      expect(c.error, isNull);
      await c.loadMore();
      expect(c.records, [1]);
      expect(c.loadMoreError, 'page failed');
    });

    test('has_more with an empty page stops pagination', () async {
      final c = ManagerListController<int>(
        fetchPage: (_) async => _page([], total: 5, more: true),
      );
      await c.reload();
      expect(c.hasMore, false);
    });
  });

  group('DashboardPeriod', () {
    final now = DateTime(2026, 10, 9, 15, 30); // Friday
    test('ranges', () {
      expect(DashboardPeriod.today.range(now).start, DateTime(2026, 10, 9));
      expect(DashboardPeriod.today.range(now).end, DateTime(2026, 10, 9));
      expect(DashboardPeriod.week.range(now).start, DateTime(2026, 10, 5));
      expect(DashboardPeriod.month.range(now).start, DateTime(2026, 10, 1));
    });
  });

  test('ManagerQuery omits empty filters', () {
    final p = ManagerQuery(
      search: '  ',
      dateRange: DateTimeRange(
        start: DateTime(2026, 1, 2),
        end: DateTime(2026, 1, 3),
      ),
    ).toParams();
    expect(p.containsKey('search'), false);
    expect(p.containsKey('sales_person'), false);
    expect(p['from_date'], '2026-01-02');
  });
}
