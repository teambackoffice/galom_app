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

      if (sid == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final uri = Uri.parse(url);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          return modeOfPaymentModalFromJson(response.body);
        } catch (e, stackTrace) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception(
          'Failed to load mode of payment. Code: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}
