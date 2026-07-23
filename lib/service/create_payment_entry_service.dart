import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class CreatePaymentEntryService {
  final String url =
      '${ApiConstants.baseUrl}create_payment_entry_from_sales_invoices';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> _getSid() async {
    return await storage.read(key: "sid");
  }

  Future<String?> _getSalesPerson() async {
    return await storage.read(key: "sales_person_id");
  }

  Future<http.Response> createPayment({
    required String customer,
    required double totalAllocatedAmount,
    required String modeOfPayment,
    required List<Map<String, dynamic>> invoiceAllocations,
    String? referenceNumber,
    String? referenceDate,
  }) async {
    try {
      final sid = await _getSid();
      final salesPerson = await _getSalesPerson();

      if (sid == null || sid.isEmpty) {
        throw Exception("SID not found in storage");
      }

      if (salesPerson == null || salesPerson.isEmpty) {
        throw Exception("Sales person not found in storage");
      }

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sid',
      };

      final Map<String, dynamic> requestBody = {
        "customer": customer,
        "total_allocated_amount": totalAllocatedAmount,
        "sales_person": salesPerson,
        "mode_of_payment": modeOfPayment,
        "invoice_allocations": invoiceAllocations,
      };

      if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
        requestBody["reference_no"] = referenceNumber.trim();
      }

      if (referenceDate != null && referenceDate.trim().isNotEmpty) {
        requestBody["reference_date"] = referenceDate.trim();
      }

      final body = jsonEncode(requestBody);

      // ================= REQUEST =================
      debugPrint("========== CREATE PAYMENT ENTRY ==========");
      debugPrint("URL: $url");
      debugPrint("Method: POST");
      debugPrint("SID: $sid");
      debugPrint("Sales Person: $salesPerson");
      debugPrint("Headers:");
      debugPrint(headers.toString());

      const encoder = JsonEncoder.withIndent('  ');
      debugPrint("Request Body:");
      debugPrint(encoder.convert(requestBody));
      debugPrint("=========================================");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      // ================= RESPONSE =================
      debugPrint("========== API RESPONSE ==========");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Reason: ${response.reasonPhrase}");
      debugPrint("Headers:");
      debugPrint(response.headers.toString());

      debugPrint("Response Body:");

      try {
        final decoded = jsonDecode(response.body);
        debugPrint(encoder.convert(decoded));
      } catch (_) {
        debugPrint(response.body);
      }

      debugPrint("==================================");

      return response;
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
