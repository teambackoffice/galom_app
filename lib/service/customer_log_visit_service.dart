import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class LogCustomerVisitService {
  static const _storage = FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}log_customer_visit';

  /// Logs a customer visit
  Future<Map<String, dynamic>> logCustomerVisit({
    required String date,
    required String time,
    required double longitude,
    required double latitude,
    required String customerName,
    required String description,
  }) async {
    try {
      // Get SID & Sales Person from secure storage
      final sid = await _storage.read(key: 'sid');
      final salesPerson = await _storage.read(key: 'sales_person_id');

      if (sid == null || salesPerson == null) {
        throw Exception("SID or Sales Person not found in secure storage");
      }

      // Headers
      final headers = {
        'Content-Type': 'application/json',
        'Cookie':
            'sid=$sid; system_user=yes; user_id=$salesPerson; full_name=$salesPerson; user_image=',
      };

      // Request body
      final body = json.encode({
        "sales_person": salesPerson,
        "date": date,
        "time": time,
        "longitude": longitude,
        "latitude": latitude,
        "customer_name": customerName,
        "description": description,
      });

      // Create request
      final request = http.Request('POST', Uri.parse(url));
      request.body = body;
      request.headers.addAll(headers);

      // Send request
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        return decoded;
      } else {
        throw Exception(
          "Failed to log customer visit. Status: ${response.statusCode}, Body: $responseBody",
        );
      }
    } catch (e, stack) {
      throw Exception("Error logging customer visit: $e");
    }
  }
}
