import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/customer_complaint_modal.dart';
import 'package:location_tracker_app/service/customer_complaint_service.dart';

class CustomerComplaintController extends ChangeNotifier {
  final CustomerComplaintService _service = CustomerComplaintService();
  static const int _pageSize = 20;

  // ── List ──────────────────────────────────────────────────────────────────
  final List<CustomerComplaint> complaints = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _statusFilter; // null = All
  int _requestId = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  // ── Create ────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  // ── Detail ────────────────────────────────────────────────────────────────
  CustomerComplaint? detail;
  bool _isDetailLoading = false;
  String? _detailError;

  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;

  String? sid;

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  void setStatusFilter(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    sid ??= await _service.readSid();
    try {
      final result = await _service.getComplaints(
        status: _statusFilter,
        limit: _pageSize,
        offset: 0,
      );
      if (requestId != _requestId) return;
      complaints
        ..clear()
        ..addAll(result.complaints);
      _hasMore = result.complaints.length >= _pageSize;
    } catch (e) {
      if (requestId != _requestId) return;
      complaints.clear();
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
      final result = await _service.getComplaints(
        status: _statusFilter,
        limit: _pageSize,
        offset: complaints.length,
      );
      if (requestId != _requestId) return;
      complaints.addAll(result.complaints);
      _hasMore = result.complaints.length >= _pageSize;
    } catch (_) {
      // Keep what is already loaded; the user can pull to refresh.
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
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
      detail = await _service.getComplaintDetail(name);
    } catch (e) {
      _detailError = _clean(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Returns the created complaint, or null on failure (see [submitError]).
  Future<CustomerComplaint?> createComplaint(
    CreateComplaintRequest request, {
    File? attachment,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      final created = await _service.createComplaint(
        request,
        attachment: attachment,
      );
      fetchComplaints();
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
