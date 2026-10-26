import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/manager/manager_stock_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/service/manager_stock_service.dart';

enum StockFilter {
  all('All'),
  low('Low stock'),
  out('Out of stock');

  const StockFilter(this.label);
  final String label;
}

/// Stock list with name search, item group, and low / out-of-stock filters. The endpoint
/// returns all items at once, so filtering here covers the complete data.
class ManagerStockController with ChangeNotifier {
  ManagerStockController({ManagerStockService? service})
    : _service = service ?? ManagerStockService();

  final ManagerStockService _service;

  /// The API has no reorder level, so "low" uses this adjustable limit.
  static const List<double> thresholdOptions = [5, 10, 20, 50, 100];

  List<StockItem> _all = const [];
  bool _isLoading = false;
  bool _loadedOnce = false;
  ManagerApiException? _error;
  StockFilter _filter = StockFilter.all;
  String _search = '';
  String? _itemGroup;
  double _lowThreshold = 10;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _loadedOnce;
  ManagerApiException? get error => _error;
  StockFilter get filter => _filter;
  String get search => _search;
  double get lowThreshold => _lowThreshold;

  /// Selected item group, or null for all groups.
  String? get itemGroup => _itemGroup;

  /// Item groups present in the loaded stock, alphabetical.
  List<String> get itemGroups {
    final groups = {
      for (final i in _all)
        if (i.itemGroup != null && i.itemGroup!.trim().isNotEmpty)
          i.itemGroup!.trim(),
    }.toList();
    groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return groups;
  }

  int get totalItems => _all.length;

  int groupCount(String group) =>
      _all.where((i) => i.itemGroup?.trim() == group).length;

  bool _inGroup(StockItem i) =>
      _itemGroup == null || i.itemGroup?.trim() == _itemGroup;

  bool _matches(StockItem i, StockFilter f) => switch (f) {
    StockFilter.all => true,
    StockFilter.low => i.isLow(_lowThreshold),
    StockFilter.out => i.isOutOfStock,
  };

  /// Counts within the selected item group.
  int count(StockFilter f) =>
      _all.where((i) => _inGroup(i) && _matches(i, f)).length;

  List<StockItem> get visible {
    final q = _search.toLowerCase();
    return _all.where((i) {
      if (!_inGroup(i) || !_matches(i, _filter)) return false;
      if (q.isEmpty) return true;
      return i.displayName.toLowerCase().contains(q) ||
          i.itemCode.toLowerCase().contains(q);
    }).toList();
  }

  void ensureLoaded() {
    if (!_loadedOnce && !_isLoading) load();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final items = await _service.getStock();
      // Most urgent first: out of stock, then lowest quantity; then by name.
      items.sort((a, b) {
        final q = a.totalQty.compareTo(b.totalQty);
        if (q != 0) return q;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
      _all = List.unmodifiable(items);
      if (_itemGroup != null && !itemGroups.contains(_itemGroup)) {
        _itemGroup = null;
      }
      _loadedOnce = true;
    } on ManagerApiException catch (e) {
      _error = e;
    } catch (e) {
      debugPrint('Stock parse error: $e');
      _error = const ManagerApiException(
        'Unexpected response from the server.',
      );
    }
    _isLoading = false;
    _notify();
  }

  void setFilter(StockFilter f) {
    if (f == _filter) return;
    _filter = f;
    _notify();
  }

  void setSearch(String text) {
    final v = text.trim();
    if (v == _search) return;
    _search = v;
    _notify();
  }

  void setItemGroup(String? group) {
    if (group == _itemGroup) return;
    _itemGroup = group;
    _notify();
  }

  void setLowThreshold(double value) {
    if (value == _lowThreshold || value < 0) return;
    _lowThreshold = value;
    _notify();
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
