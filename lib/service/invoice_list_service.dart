import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';

class InvoiceListService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}get_sales_invoice_list';

  /// [month] is `YYYY-MM`; null means all months.
  Future<InvoiceListModal?> getInvoiceList({String? month}) async {
    try {
      final String? sid = await _secureStorage.read(key: 'sid');
      final String? salesPersonId = await _secureStorage.read(
        key: 'sales_person_id',
      );

      if (sid == null || salesPersonId == null) {
        throw Exception('Authentication required. Please login again.');
      }

      // Build request URL with sales person ID
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'sales_person': salesPersonId,
          if (month != null) 'month': month,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      if (response.statusCode == 200) {
        print("===== Sales invoice List ====");
        print(response.body);
        try {
          final decoded = jsonDecode(response.body);
          return invoiceListModalFromJson(response.body);
        } catch (e) {
          print("errorssss $e");
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception(
          'Failed to load invoices. Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("error $e");
      throw Exception('Network error: $e');
    }
  }
}
