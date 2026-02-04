import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/payment_entry_modal.dart';
import 'package:location_tracker_app/service/payment_entry_service.dart';

class PaymentEntryController with ChangeNotifier {
  final PaymentEntryService _service = PaymentEntryService();

  PaymentEntryModal? _paymentEntry;
  bool _isLoading = false;
  String? _error;

  PaymentEntryModal? get paymentEntry => _paymentEntry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch Payment Entry data
  Future<void> fetchPaymentEntry({required String customer}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getCustomerPaymentEntry(customer: customer);
      _paymentEntry = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
