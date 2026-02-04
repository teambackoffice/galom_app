import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';
import 'package:location_tracker_app/service/invoice_list_service.dart';

class InvoiceListController extends ChangeNotifier {
  final InvoiceListService _service = InvoiceListService();
  bool _isLoading = false;
  String? _error;
  InvoiceListModal? invoiceList;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInvoiceList() async {
    setLoading(true);
    notifyListeners();
    try {
      invoiceList = await _service.getInvoiceList();
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
