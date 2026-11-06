import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Filters shared by every manager list.
@immutable
class ManagerFilters {
  final String search;
  final SalesPerson? salesPerson;
  final DateTimeRange? dateRange;
  final String? status;

  const ManagerFilters({
    this.search = '',
    this.salesPerson,
    this.dateRange,
    this.status,
  });

  bool get isActive =>
      search.isNotEmpty ||
      salesPerson != null ||
      dateRange != null ||
      status != null;

  ManagerQuery toQuery({required int start, required int pageLength}) =>
      ManagerQuery(
        salesPerson: salesPerson?.name,
        dateRange: dateRange,
        search: search,
        status: status,
        start: start,
        pageLength: pageLength,
      );
}

/// Server-side filtered, paginated list for one manager module.
///
/// - Any filter change resets to `start=0` and replaces the list.
/// - [loadMore] appends using `start = records.length` while `has_more`.
/// - A generation counter discards responses that arrive after the filters
///   changed, so stale data never replaces newer results.
class ManagerListController<T> with ChangeNotifier {
  ManagerListController({
    required Future<ManagerPage<T>> Function(ManagerQuery query) fetchPage,
    this.pageLength = 20,
    this.searchDebounce = const Duration(milliseconds: 500),
  }) : _fetchPage = fetchPage;

  final Future<ManagerPage<T>> Function(ManagerQuery query) _fetchPage;
  final int pageLength;
  final Duration searchDebounce;

  ManagerFilters _filters = const ManagerFilters();
  List<T> _records = const [];
  int _totalCount = 0;
  Map<String, double> _totals = const {};
  bool _hasMore = false;

  bool _isLoading = false;
  bool _isRefreshing = false;
  ManagerApiException? _error;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  bool _loadedOnce = false;

  int _generation = 0;
  int _clearCount = 0;
  Timer? _debounce;
  bool _disposed = false;

  ManagerFilters get filters => _filters;
  List<T> get records => _records;
  int get totalCount => _totalCount;
  Map<String, double> get totals => _totals;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  ManagerApiException? get error => _error;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;
  bool get hasLoaded => _loadedOnce;

  /// Loads the first page once; later calls are no-ops.
  void ensureLoaded() {
    if (!_loadedOnce && !_isLoading && _error == null) reload();
  }

  /// Reloads from `start=0`. When [keepVisible] is true (pull-to-refresh)
  /// the current rows stay on screen until the new page arrives.
  Future<void> reload({bool keepVisible = false}) async {
    _debounce?.cancel();
    final gen = ++_generation;
    _isLoading = !keepVisible || _records.isEmpty;
    _isRefreshing = keepVisible;
    _isLoadingMore = false;
    _loadMoreError = null;
    _error = null;
    if (_isLoading) _records = const [];
    _notify();

    try {
      final page = await _fetchPage(
        _filters.toQuery(start: 0, pageLength: pageLength),
      );
      if (gen != _generation || _disposed) return;
      _records = List.unmodifiable(page.records);
      _applyMeta(page);
      _loadedOnce = true;
    } on ManagerApiException catch (e) {
      if (gen != _generation || _disposed) return;
      _error = e;
      _records = const [];
    } catch (e) {
      if (gen != _generation || _disposed) return;
      debugPrint('Manager list parse error: $e');
      _error = const ManagerApiException(
        'Unexpected response from the server.',
      );
      _records = const [];
    }
    _isLoading = false;
    _isRefreshing = false;
    _notify();
  }

  Future<void> refresh() => reload(keepVisible: true);

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading || _error != null) return;
    final gen = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    _notify();

    try {
      final page = await _fetchPage(
        _filters.toQuery(start: _records.length, pageLength: pageLength),
      );
      if (gen != _generation || _disposed) return;
      _records = List.unmodifiable([..._records, ...page.records]);
      _applyMeta(page);
    } on ManagerApiException catch (e) {
      if (gen != _generation || _disposed) return;
      _loadMoreError = e.message;
    } catch (_) {
      if (gen != _generation || _disposed) return;
      _loadMoreError = 'Unexpected response from the server.';
    }
    _isLoadingMore = false;
    _notify();
  }

  void _applyMeta(ManagerPage<T> page) {
    _totalCount = page.totalCount;
    _totals = Map.unmodifiable(page.totals);
    // Guard against an endless loop if the server reports more but sends none.
    _hasMore = page.hasMore && page.records.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  void onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () => _setSearch(text));
  }

  /// Applies the search immediately (keyboard "search" action).
  void submitSearch(String text) {
    _debounce?.cancel();
    _setSearch(text);
  }

  void _setSearch(String text) {
    final value = text.trim();
    if (value == _filters.search) return;
    _filters = ManagerFilters(
      search: value,
      salesPerson: _filters.salesPerson,
      dateRange: _filters.dateRange,
      status: _filters.status,
    );
    reload();
  }

  void setSalesPerson(SalesPerson? salesPerson) {
    if (salesPerson == _filters.salesPerson) return;
    _filters = ManagerFilters(
      search: _filters.search,
      salesPerson: salesPerson,
      dateRange: _filters.dateRange,
      status: _filters.status,
    );
    reload();
  }

  void setDateRange(DateTimeRange? range) {
    if (range == _filters.dateRange) return;
    _filters = ManagerFilters(
      search: _filters.search,
      salesPerson: _filters.salesPerson,
      dateRange: range,
      status: _filters.status,
    );
    reload();
  }

  void setStatus(String? status) {
    if (status == _filters.status) return;
    _filters = ManagerFilters(
      search: _filters.search,
      salesPerson: _filters.salesPerson,
      dateRange: _filters.dateRange,
      status: status,
    );
    reload();
  }

  void clearFilters() {
    _debounce?.cancel();
    _clearCount++;
    if (!_filters.isActive) {
      _notify();
      return;
    }
    _filters = const ManagerFilters();
    reload();
  }

  /// Increments on every [clearFilters] so the search box can reset itself.
  int get clearCount => _clearCount;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
