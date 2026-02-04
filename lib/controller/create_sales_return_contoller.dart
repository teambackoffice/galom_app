import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/service/create_sales_return_service.dart';

class CreateSalesReturnController with ChangeNotifier {
  final CreateSalesReturnService _salesReturnService =
      CreateSalesReturnService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? responseData;

  Future<void> createSalesReturn({
    String? returnAgainst,
    String? returnDate,
    String? customer,
    String? reason,
    String? buyingDate,
    String? return_reason,
    List<Map<String, dynamic>>? items,
  }) async {
    isLoading = true;
    errorMessage = null;
    responseData = null;
    notifyListeners();

    try {
      final response = await _salesReturnService.createSalesReturn(
        returnAgainst: returnAgainst,
        returnDate: returnDate,
        customer: customer,
        reason: reason,
        return_reason: return_reason,
        items: items,
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
