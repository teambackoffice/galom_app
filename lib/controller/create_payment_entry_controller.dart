import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/service/create_payment_entry_service.dart';

class CraetePaymentEntryController with ChangeNotifier {
  final CreatePaymentEntryService _paymentService = CreatePaymentEntryService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? responseData;

  Future<void> createPayment({
    required String customer,
    required double totalAllocatedAmount,
    required String modeOfPayment,
    required List<Map<String, dynamic>> invoiceAllocations,
    String? referenceNumber,
    String? referenceDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    responseData = null;
    notifyListeners();

    try {
      final response = await _paymentService.createPayment(
        customer: customer,
        totalAllocatedAmount: totalAllocatedAmount,
        modeOfPayment: modeOfPayment,
        invoiceAllocations: invoiceAllocations,
        referenceNumber: referenceNumber,
        referenceDate: referenceDate,
      );

      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
      } else {
        errorMessage = "Error: ${response.reasonPhrase}";
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
