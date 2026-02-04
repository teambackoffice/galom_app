import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class CreateSalesReturnService {
  final String url = '${ApiConstants.baseUrl}create_sales_return';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Fetch SID from secure storage
  Future<String?> _getSid() async {
    return await storage.read(key: "sid");
  }

  /// Fetch ID from secure storage
  Future<String?> _getId() async {
    return await storage.read(key: "sales_person_id");
  }

  Future<http.Response> createSalesReturn({
    String? returnAgainst,
    String? returnDate,
    String? customer,
    String? salesPerson,
    List<Map<String, dynamic>>? items,
    String? reason,
    String? return_reason,
  }) async {
    final sid = await _getSid();
    if (sid == null || sid.isEmpty) {
      throw Exception("SID not found in storage");
    }

    final id = await _getId();
    if (id == null || id.isEmpty) {
      throw Exception("ID not found in storage");
    }

    final headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

    final Map<String, dynamic> body = {"sales_person": salesPerson ?? id};

    if (returnAgainst?.isNotEmpty ?? false)
      body["return_against"] = returnAgainst;
    if (returnDate?.isNotEmpty ?? false) body["return_date"] = returnDate;
    if (customer?.isNotEmpty ?? false) body["customer"] = customer;
    if (reason?.isNotEmpty ?? false) body["reason"] = reason;
    if (return_reason?.isNotEmpty ?? false)
      body["return_reason"] = return_reason;
    if (items != null && items.isNotEmpty) body["items"] = items;

    final uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    return response;
  }
}
