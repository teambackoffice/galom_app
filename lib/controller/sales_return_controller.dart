import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/sales_return_modal.dart';
import 'package:location_tracker_app/service/sales_return_service.dart';

class SalesReturnController extends ChangeNotifier {
  final SalesReturnService _service = SalesReturnService();
  bool _isLoading = false;
  String? _error;
  SalesReturnModal? salesreturnList;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchsalesreturn() async {
    setLoading(true);
    notifyListeners();
    try {
      salesreturnList = await _service.getSalesReturn();
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
