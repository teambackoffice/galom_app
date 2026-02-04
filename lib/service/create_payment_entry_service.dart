import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class CreatePaymentEntryService {
  final String url =
      '${ApiConstants.baseUrl}create_payment_entry_from_sales_invoices';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Fetch SID from secure storage
  Future<String?> _getSid() async {
    return await storage.read(key: "sid");
  }

  /// Fetch sales person from secure storage
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
    final sid = await _getSid();
    final salesPerson = await _getSalesPerson();

    if (sid == null || sid.isEmpty) {
      throw Exception("SID not found in storage");
    }
    if (salesPerson == null || salesPerson.isEmpty) {
      throw Exception("Sales person not found in storage");
    }

    final headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

    // Build the request body with proper null handling
    Map<String, dynamic> requestBody = {
      "customer": customer,
      "total_allocated_amount": totalAllocatedAmount,
      "sales_person": salesPerson,
      "mode_of_payment": modeOfPayment,
      "invoice_allocations": invoiceAllocations,
      "reference_no": referenceNumber ?? "",
      "reference_date": referenceDate ?? "",
    };

    // Only add reference fields if they have values
    if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
      requestBody["reference_no"] = referenceNumber.trim();
    }

    if (referenceDate != null && referenceDate.trim().isNotEmpty) {
      requestBody["reference_date"] = referenceDate.trim();
    }

    final body = json.encode(requestBody);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    return response;
  }
}
