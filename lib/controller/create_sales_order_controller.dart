import 'package:flutter/material.dart';

import '../service/create_sales_order_service.dart';

class CreateSalesOrderController extends ChangeNotifier {
  final CreateSalesOrderService _service = CreateSalesOrderService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get response => _response;

  Future<void> createSalesOrder({
    required String customer,
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    _response = null;
    notifyListeners();

    try {
      _response = await _service.createSalesOrder(
        customer: customer,
        deliveryDate: deliveryDate,
        items: items,
      );

      // NEW: Check if the API response contains an error
      if (_response != null && _response!['message'] != null) {
        final message = _response!['message'];

        if (message is Map && message['status'] == 'error') {
          final errorMessage = message['message'];

          if (errorMessage is String) {
            // single error string
            _error = errorMessage;
          } else if (errorMessage is List) {
            // multiple errors → bullet points, new lines
            _error = errorMessage.map((e) => "• $e").join("\n");
          } else {
            _error = 'An unknown error occurred';
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
