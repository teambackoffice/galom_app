import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location_tracker_app/config/api_constant.dart';

class PaySalesInvoiceService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}pay_sales_invoice';

  Future<Map<String, dynamic>> paySalesInvoice({
    required String invoice_id,
    required String amount,
    required String modeOfPayment,
    String? referenceNumber,
    DateTime? referenceDate,
  }) async {
    try {
      final sid = await _secureStorage.read(key: 'sid');

      if (sid == null) {
        throw Exception('Session ID not found. Please log in again.');
      }

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      final Map<String, dynamic> bodyMap = {
        "invoice_name": invoice_id,
        "payment_amount": amount,
        "mode_of_payment": modeOfPayment,
      };

      if (referenceNumber != null && referenceNumber.isNotEmpty) {
        bodyMap["reference_no"] = referenceNumber;
      }

      if (referenceDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(referenceDate);
        bodyMap["reference_date"] = formattedDate;
      }

      final body = json.encode(bodyMap);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        return decodedResponse;
      } else {
        throw Exception(
          'Failed to pay sales invoice.\n'
          'Status Code: ${response.statusCode}\n'
          'Response: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}
