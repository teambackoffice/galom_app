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

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sid',
      };

      final Map<String, dynamic> bodyMap = {
        "invoice_name": invoice_id,
        "payment_amount": amount,
        "mode_of_payment": modeOfPayment,
      };

      if (referenceNumber != null && referenceNumber.isNotEmpty) {
        bodyMap["reference_no"] = referenceNumber;
      }

      if (referenceDate != null) {
        bodyMap["reference_date"] = DateFormat(
          'yyyy-MM-dd',
        ).format(referenceDate);
      }

      final body = json.encode(bodyMap);

      // ================= REQUEST =================
      debugPrint("========== PAY SALES INVOICE ==========");
      debugPrint("URL: $url");
      debugPrint("Method: POST");
      debugPrint("SID: $sid");
      debugPrint("Headers:");
      debugPrint(headers.toString());

      const encoder = JsonEncoder.withIndent('  ');
      debugPrint("Request Body:");
      debugPrint(encoder.convert(bodyMap));
      debugPrint("=======================================");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      // ================= RESPONSE =================
      debugPrint("========== API RESPONSE ==========");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Reason Phrase: ${response.reasonPhrase}");
      debugPrint("Response Headers:");
      debugPrint(response.headers.toString());

      debugPrint("Response Body:");

      try {
        final decoded = json.decode(response.body);
        debugPrint(encoder.convert(decoded));
      } catch (_) {
        debugPrint(response.body);
      }

      debugPrint("==================================");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("========== HTTP ERROR ==========");
        debugPrint("Status Code: ${response.statusCode}");
        debugPrint("Reason Phrase: ${response.reasonPhrase}");
        debugPrint("Response Body:");
        debugPrint(response.body);
        debugPrint("================================");

        throw Exception(
          'Failed to pay sales invoice.\n'
          'Status Code: ${response.statusCode}\n'
          'Response: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint("========== EXCEPTION ==========");
      debugPrint("Error: $e");
      debugPrint("Type: ${e.runtimeType}");
      debugPrint("StackTrace:");
      debugPrint(stackTrace.toString());
      debugPrint("===============================");

      rethrow;
    }
  }
}
