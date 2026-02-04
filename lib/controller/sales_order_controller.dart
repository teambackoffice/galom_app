import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/sales_order_modal.dart';
import 'package:location_tracker_app/service/sales_order_service.dart';

class SalesOrderController extends ChangeNotifier {
  final SalesOrderService _service = SalesOrderService();
  bool _isLoading = false;
  String? _error;
  SalesOrderModal? salesorder;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchsalesorder() async {
    setLoading(true);
    notifyListeners();
    try {
      salesorder = await _service.getsalesorder();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
