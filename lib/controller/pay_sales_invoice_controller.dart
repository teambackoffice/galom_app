import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/pay_sales_invoice_service.dart';

class PaySalesInvoiceController extends ChangeNotifier {
  final PaySalesInvoiceService _service = PaySalesInvoiceService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get response => _response;

  Future<void> paySalesInvoice({
    required String invoice_id,
    required String amount,
    required String mode_of_payment,
    String? referenceNumber, // optional
    DateTime? referenceDate, // optional
  }) async {
    _isLoading = true;
    _error = null;
    _response = null;
    notifyListeners();

    try {
      _response = await _service.paySalesInvoice(
        invoice_id: invoice_id,
        amount: amount,
        modeOfPayment: mode_of_payment,
        referenceNumber: referenceNumber,
        referenceDate: referenceDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
