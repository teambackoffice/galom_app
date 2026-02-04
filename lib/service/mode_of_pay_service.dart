import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/mode_of_payment.dart';

class ModeOfPayService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}get_mode_of_payment';

  Future<ModeOfPaymentModal?> getmodeofpay() async {
    try {
      final String? sid = await _secureStorage.read(key: 'sid');
      if (sid == null)
        throw Exception('Authentication required. Please login again.');

      // Log the request details

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      // Log the response details

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return modeOfPaymentModalFromJson(response.body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception(
          'Failed to load mode of payment. Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
