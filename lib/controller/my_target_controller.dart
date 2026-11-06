import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/modal/my_target_modal.dart';
import 'package:location_tracker_app/service/my_target_service.dart';

class MyTargetController extends ChangeNotifier {
  final MyTargetService _service = MyTargetService();

  bool _isLoading = false;
  String? _error;
  MyTargetModal? target;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Current-month summary, kept separately so the Invoices banner is not
  // affected by whatever month the My Target screen is browsing.
  bool _isSummaryLoading = false;
  String? _summaryError;
  MyTargetModal? currentMonthTarget;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSummaryLoading => _isSummaryLoading;
  String? get summaryError => _summaryError;
  DateTime get selectedMonth => _selectedMonth;
  String get selectedMonthParam => DateFormat('yyyy-MM').format(_selectedMonth);
  String get selectedMonthLabel =>
      DateFormat('MMMM yyyy').format(_selectedMonth);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Future<void> fetchTarget() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final requested = selectedMonthParam;
    try {
      final result = await _service.getMyMonthlyTarget(month: requested);
      // Ignore stale responses if the month changed while loading.
      if (requested != selectedMonthParam) return;
      target = result;
      if (isCurrentMonth) currentMonthTarget = result;
    } catch (e) {
      if (requested != selectedMonthParam) return;
      target = null;
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (requested == selectedMonthParam) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchCurrentMonthSummary() async {
    _isSummaryLoading = true;
    _summaryError = null;
    notifyListeners();
    try {
      currentMonthTarget = await _service.getMyMonthlyTarget(
        month: DateFormat('yyyy-MM').format(DateTime.now()),
      );
    } catch (e) {
      currentMonthTarget = null;
      _summaryError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  void resetToCurrentMonth() {
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    fetchTarget();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    fetchTarget();
  }
}
