import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/manager/manager_leave_modal.dart';
import 'package:location_tracker_app/service/manager_leave_service.dart';
import 'package:location_tracker_app/service/manager_service.dart';

enum LeaveFilter {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  all('All');

  const LeaveFilter(this.label);
  final String label;

  bool matches(LeaveApplication l) => switch (this) {
    LeaveFilter.pending => l.isPending,
    LeaveFilter.approved => l.status == 'Approved',
    LeaveFilter.rejected => l.status == 'Rejected',
    LeaveFilter.all => true,
  };
}

/// Leave applications for the manager. The endpoint returns the full list
/// (no paging or server filters), so filtering here is over complete data.
class ManagerLeaveController with ChangeNotifier {
  ManagerLeaveController({ManagerLeaveService? service})
    : _service = service ?? ManagerLeaveService();

  final ManagerLeaveService _service;

  List<LeaveApplication> _all = const [];
  bool _isLoading = false;
  bool _loadedOnce = false;
  ManagerApiException? _error;
  LeaveFilter _filter = LeaveFilter.pending;
  String _search = '';
  final Set<String> _busy = {};
  bool _disposed = false;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _loadedOnce;
  ManagerApiException? get error => _error;
  LeaveFilter get filter => _filter;
  String get search => _search;
  bool isBusy(String name) => _busy.contains(name);

  int get pendingCount => _all.where((l) => l.isPending).length;
  int count(LeaveFilter f) => _all.where(f.matches).length;

  List<LeaveApplication> get visible {
    final q = _search.toLowerCase();
    return _all.where((l) {
      if (!_filter.matches(l)) return false;
      if (q.isEmpty) return true;
      return l.displayName.toLowerCase().contains(q) ||
          l.leaveType.toLowerCase().contains(q) ||
          l.employee.toLowerCase().contains(q);
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
      final list = await _service.getLeaveApplications();
      // Pending first, then newest start date.
      list.sort((a, b) {
        if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
        final ad = a.fromDate ?? a.postingDate;
        final bd = b.fromDate ?? b.postingDate;
        if (ad == null || bd == null) return 0;
        return bd.compareTo(ad);
      });
      _all = List.unmodifiable(list);
      _loadedOnce = true;
    } on ManagerApiException catch (e) {
      _error = e;
    } catch (e) {
      debugPrint('Leave parse error: $e');
      _error = const ManagerApiException(
        'Unexpected response from the server.',
      );
    }
    _isLoading = false;
    _notify();
  }

  void setFilter(LeaveFilter f) {
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

  /// Returns null on success, or an error message to show.
  Future<String?> approve(LeaveApplication l) =>
      _act(l, () => _service.approve(l.name), 'Approved');

  Future<String?> reject(LeaveApplication l) =>
      _act(l, () => _service.reject(l.name), 'Rejected');

  Future<String?> _act(
    LeaveApplication l,
    Future<void> Function() call,
    String newStatus,
  ) async {
    if (_busy.contains(l.name)) return null;
    _busy.add(l.name);
    _notify();
    String? error;
    try {
      await call();
      _all = List.unmodifiable(
        _all.map((x) => x.name == l.name ? x.copyWith(status: newStatus) : x),
      );
    } on ManagerApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not update the leave application.';
    }
    _busy.remove(l.name);
    _notify();
    return error;
  }

  LeaveApplication? byName(String name) {
    for (final l in _all) {
      if (l.name == name) return l;
    }
    return null;
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
