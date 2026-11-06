import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';
import 'package:location_tracker_app/service/customer_list_service.dart';
import 'package:location_tracker_app/service/invoice_list_service.dart';

class InvoiceListController extends ChangeNotifier {
  final InvoiceListService _service = InvoiceListService();
  final CustomerListService _customerService = CustomerListService();
  bool _isLoading = false;
  String? _error;
  InvoiceListModal? invoiceList;

  // Filters; null means "All".
  DateTime? _selectedMonth;
  MessageElement? _selectedCustomer;
  List<MessageElement> customers = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get selectedMonth => _selectedMonth;
  MessageElement? get selectedCustomer => _selectedCustomer;

  Future<void> fetchInvoiceList() async {
    setLoading(true);
    notifyListeners();
    try {
      invoiceList = await _service.getInvoiceList(
        month: _selectedMonth == null
            ? null
            : DateFormat('yyyy-MM').format(_selectedMonth!),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchCustomers() async {
    try {
      customers = (await _customerService.fetchCustomerList()).message.message;
      notifyListeners();
    } catch (_) {
      // The filter just shows "All customers" if this fails.
    }
  }

  Future<void> setMonth(DateTime? month) {
    _selectedMonth = month;
    return fetchInvoiceList();
  }

  // Customer filter is applied locally; the API has no customer param.
  void setCustomer(MessageElement? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    final hadMonth = _selectedMonth != null;
    _selectedMonth = null;
    _selectedCustomer = null;
    if (hadMonth) {
      await fetchInvoiceList();
    } else {
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
