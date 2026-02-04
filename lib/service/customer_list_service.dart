import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';

class CustomerListService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<CustomerListModal> fetchCustomerList() async {
    final String url = '${ApiConstants.baseUrl}get_customers';

    try {
      final String? sid = await _secureStorage.read(key: 'sid');

      if (sid == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      // PRINT STATUS CODE

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          return CustomerListModal.fromJson(decoded);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception(
          'Failed to load customers. Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
