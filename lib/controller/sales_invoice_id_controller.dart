import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/sales_invoice_id_modal.dart';
import 'package:location_tracker_app/service/sales_invoice_id_service.dart';

class SalesInvoiceIdsController extends ChangeNotifier {
  final SalesInvoiceIdsService _service = SalesInvoiceIdsService();

  bool isLoading = false;
  String? error;
  SalesInvoiceIdsModel? salesInvoiceIds;

  Future<void> getSalesInvoiceIds() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      salesInvoiceIds = await _service.fetchSalesInvoiceIds();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
