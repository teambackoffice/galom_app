import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/sales_invoice_details.dart';

class SalesInvoiceDetailService {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = '${ApiConstants.baseUrl}sales_invoice_detail_by_ids';

  Future<SalesInvoiceDeatailsModal?> fetchSalesInvoiceDetail(
    String invoiceId,
  ) async {
    try {
      // Read sid from secure storage
      final sid = await _storage.read(key: 'sid');
      if (sid == null) {
        return null;
      }

      // Prepare headers
      var headers = {'Cookie': 'sid=$sid'};

      // Prepare request
      final uri = Uri.parse('$baseUrl?invoice_id=$invoiceId');

      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        final jsonMap = jsonDecode(responseBody);
        return SalesInvoiceDeatailsModal.fromJson(jsonMap);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
