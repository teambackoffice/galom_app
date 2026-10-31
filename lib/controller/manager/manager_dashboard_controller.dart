import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

enum DashboardPeriod {
  today('Today'),
  week('This week'),
  month('This month');

  const DashboardPeriod(this.label);
  final String label;

  DateTimeRange range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DashboardPeriod.today:
        return DateTimeRange(start: today, end: today);
      case DashboardPeriod.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: monday, end: today);
      case DashboardPeriod.month:
        return DateTimeRange(start: DateTime(now.year, now.month), end: today);
    }
  }
}

/// Summary for one module over the selected period, built from a single
/// small list request (`total_count` + `totals` + the newest rows).
class ModuleSummary {
  final bool isLoading;
  final String? error;
  final int totalCount;
  final Map<String, double> totals;
  final List<Object> recent;

  const ModuleSummary({
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.totals = const {},
    this.recent = const [],
  });

  const ModuleSummary.loading() : this(isLoading: true);

  bool get hasData => !isLoading && error == null;
}

class ManagerDashboardController with ChangeNotifier {
  ManagerDashboardController({
    ManagerService? service,
    DateTime Function()? clock,
  }) : _service = service ?? ManagerService(),
       _clock = clock ?? DateTime.now;

  final ManagerService _service;
  final DateTime Function() _clock;

  /// Only `total_count` and `totals` are used, so fetch a single row.
  static const int summaryPageLength = 1;

  DashboardPeriod _period = DashboardPeriod.today;
  final Map<ManagerModule, ModuleSummary> _summaries = {
    for (final m in ManagerModule.values) m: const ModuleSummary.loading(),
  };
  int _generation = 0;
  bool _loadedOnce = false;
  bool _disposed = false;

  DashboardPeriod get period => _period;
  DateTimeRange get range => _period.range(_clock());
  ModuleSummary summary(ManagerModule m) => _summaries[m]!;

  void ensureLoaded() {
    if (!_loadedOnce) load();
  }

  void setPeriod(DashboardPeriod period) {
    if (period == _period) return;
    _period = period;
    load();
  }

  /// Loads every module independently so one failure never blocks the rest.
  Future<void> load() async {
    _loadedOnce = true;
    final gen = ++_generation;
    for (final m in ManagerModule.values) {
      _summaries[m] = const ModuleSummary.loading();
    }
    _notify();

    final query = ManagerQuery(
      dateRange: range,
      start: 0,
      pageLength: summaryPageLength,
    );
    await Future.wait(ManagerModule.values.map((m) => _loadOne(m, query, gen)));
  }

  Future<void> retry(ManagerModule module) async {
    final gen = _generation;
    _summaries[module] = const ModuleSummary.loading();
    _notify();
    await _loadOne(
      module,
      ManagerQuery(dateRange: range, start: 0, pageLength: summaryPageLength),
      gen,
    );
  }

  Future<void> _loadOne(ManagerModule m, ManagerQuery q, int gen) async {
    ModuleSummary result;
    try {
      final ManagerPage<Object> page = await _fetch(m, q);
      result = ModuleSummary(
        totalCount: page.totalCount,
        totals: page.totals,
        recent: page.records,
      );
    } on ManagerApiException catch (e) {
      result = ModuleSummary(error: e.message);
    } catch (_) {
      result = const ModuleSummary(
        error: 'Unexpected response from the server.',
      );
    }
    if (gen != _generation || _disposed) return;
    _summaries[m] = result;
    _notify();
  }

  Future<ManagerPage<Object>> _fetch(ManagerModule m, ManagerQuery q) {
    switch (m) {
      case ManagerModule.attendance:
        return _service.getAttendance(q);
      case ManagerModule.visits:
        return _service.getCustomerVisits(q);
      case ManagerModule.salesOrders:
        return _service.getSalesOrders(q);
      case ManagerModule.salesReturns:
        return _service.getSalesReturns(q);
      case ManagerModule.salesInvoices:
        return _service.getSalesInvoices(q);
      case ManagerModule.payments:
        return _service.getPaymentEntries(q);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
