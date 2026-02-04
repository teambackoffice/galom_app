import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/sales_return_modal.dart';

class SalesReturnService {
  final String url = '${ApiConstants.baseUrl}get_sales_returns';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Fetch SID and Sales Person ID from secure storage
  Future<SalesReturnModal?> getSalesReturn() async {
    try {
      final String? sid = await storage.read(key: 'sid');
      final String? salesPersonId = await storage.read(key: 'sales_person_id');

      if (sid == null || salesPersonId == null) {
        throw Exception('Authentication required. Please login again.');
      }

      // Build request URL with sales person parameter
      final uri = Uri.parse(
        url,
      ).replace(queryParameters: {'sales_person': salesPersonId});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          return salesReturnModalFromJson(response.body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception(
          'Failed to load sales returns. Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
