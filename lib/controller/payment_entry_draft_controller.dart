import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/payment_entry_draft_status.dart';
import 'package:location_tracker_app/service/payment_entry_draft_service.dart';

class PaymentEntryDraftController extends ChangeNotifier {
  final PaymentEntryDraftService _service = PaymentEntryDraftService();

  bool isLoading = false;
  String? errorMessage;
  PaymentEntryDraftStatusModal? paymentEntryStatus;

  Future<void> getPaymentEntryStatus({required String customerName}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final data = await _service.fetchPaymentEntryStatus(
        customerName: customerName,
      );

      paymentEntryStatus = data;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
