import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';
import 'package:location_tracker_app/service/expense_claim_service.dart';

class ExpenseClaimController extends ChangeNotifier {
  final ExpenseClaimService _service = ExpenseClaimService();
  static const int _pageSize = 20;

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  String? sid;

  // ── List ──────────────────────────────────────────────────────────────────
  final List<ExpenseClaim> claims = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _statusFilter; // approval_status; null = All
  int _requestId = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  // ── Summary ───────────────────────────────────────────────────────────────
  ExpenseSummary? summary;

  // ── Expense types ─────────────────────────────────────────────────────────
  List<String> expenseTypes = [];
  bool _isTypesLoading = false;
  String? _typesError;

  bool get isTypesLoading => _isTypesLoading;
  String? get typesError => _typesError;

  // ── Detail ────────────────────────────────────────────────────────────────
  ExpenseClaimDetail? detail;
  bool _isDetailLoading = false;
  String? _detailError;

  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;

  // ── Create ────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  /// Loads the summary card and the first page of claims together.
  Future<void> refresh() async {
    await Future.wait([fetchSummary(), fetchClaims()]);
  }

  void setStatusFilter(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    fetchClaims();
  }

  Future<void> fetchSummary() async {
    try {
      summary = await _service.getSummary();
    } catch (_) {
      // The summary card is optional; the list shows any real error.
    }
    notifyListeners();
  }

  Future<void> fetchClaims() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    sid ??= await _service.readSid();
    try {
      final result = await _service.getMyClaims(
        status: _statusFilter,
        limit: _pageSize,
      );
      if (requestId != _requestId) return;
      claims
        ..clear()
        ..addAll(result);
      _hasMore = result.length >= _pageSize;
    } catch (e) {
      if (requestId != _requestId) return;
      claims.clear();
      _error = _clean(e);
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _service.getMyClaims(
        status: _statusFilter,
        limit: _pageSize,
        offset: claims.length,
      );
      if (requestId != _requestId) return;
      claims.addAll(result);
      _hasMore = result.length >= _pageSize;
    } catch (_) {
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpenseTypes() async {
    if (_isTypesLoading) return;
    _isTypesLoading = true;
    _typesError = null;
    notifyListeners();
    try {
      expenseTypes = await _service.getExpenseTypes();
    } catch (e) {
      _typesError = _clean(e);
    } finally {
      _isTypesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetail(String name) async {
    _isDetailLoading = true;
    _detailError = null;
    detail = null;
    notifyListeners();
    sid ??= await _service.readSid();
    try {
      detail = await _service.getClaimDetail(name);
    } catch (e) {
      _detailError = _clean(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Returns the created claim, or null on failure (see [submitError]).
  Future<CreatedExpenseClaim?> createClaim({
    required List<NewExpenseLine> lines,
    String? postingDate,
    String? remark,
    List<File> receipts = const [],
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      final created = await _service.createClaim(
        lines: lines,
        postingDate: postingDate,
        remark: remark,
        receipts: receipts,
      );
      refresh();
      return created;
    } catch (e) {
      _submitError = _clean(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
