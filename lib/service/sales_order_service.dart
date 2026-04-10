import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/sales_order_modal.dart';

class SalesOrderService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}get_sales_orders_with_details';

  Future<SalesOrderModal?> getsalesorder() async {
    try {
      // Read SID and Sales Person ID from secure storage
      final String? sid = await _secureStorage.read(key: 'sid');
      final String? salesPersonId = await _secureStorage.read(
        key: 'sales_person_id',
      );

      debugPrint('SID: $sid');
      debugPrint('Sales Person ID: $salesPersonId');

      if (sid == null) {
        throw Exception('Authentication required. Please login again.');
      }

      if (salesPersonId == null) {
        throw Exception('Sales Person ID not found in storage.');
      }

      // Build request URL with sales person filter
      final requestUrl = "$url?sales_person_id=$salesPersonId";
      debugPrint('Request URL: $requestUrl');

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          debugPrint('Decoded Response: $decoded');

          if (decoded is Map<String, dynamic>) {
            debugPrint('Response Keys: ${decoded.keys.toList()}');
          }

          final model = salesOrderModalFromJson(response.body);

          debugPrint('Parsed Model: $model');

          return model;
        } catch (e, stack) {
          debugPrint('JSON Parse Error: $e');
          debugPrint('Stack Trace: $stack');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        debugPrint('API Error Response: ${response.body}');
        throw Exception(
          'Failed to load sales orders. Code: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      debugPrint('Service Error: $e');
      debugPrint('Stack Trace: $stack');
      throw Exception('Network error: $e');
    }
  }
}
