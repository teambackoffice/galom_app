import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/sales_invoice_details.dart';
import 'package:location_tracker_app/service/sales_invoice_details_service.dart';

class SalesInvoiceDetailController extends ChangeNotifier {
  final SalesInvoiceDetailService _service = SalesInvoiceDetailService();

  SalesInvoiceDeatailsModal? salesInvoiceDetail;
  bool isLoading = false;
  String? errorMessage;

  /// Fetch invoice detail by invoice ID
  Future<void> getSalesInvoiceDetail({required String invoiceId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final data = await _service.fetchSalesInvoiceDetail(invoiceId);

    if (data != null) {
      salesInvoiceDetail = data;
    } else {
      errorMessage = "Failed to fetch invoice details.";
    }

    isLoading = false;
    notifyListeners();
  }
}
