import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class LogCustomerVisitService {
  static const _storage = FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}log_customer_visit';

  /// Logs a customer visit (multipart, with optional visit photo)
  Future<Map<String, dynamic>> logCustomerVisit({
    required String date,
    required String time,
    required double longitude,
    required double latitude,
    required String customerName,
    required String description,
    File? photo,
    bool isFirstCounter = false,
    bool isLastCounter = false,
  }) async {
    try {
      final sid = await _storage.read(key: 'sid');


      if (sid == null) {
        throw Exception("Session expired. Please log in again.");
      }

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Cookie'] = 'sid=$sid'
        ..fields.addAll({
          'customer_name': customerName,
          'description': description,
          'date': date,
          'time': time,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'is_first_counter': isFirstCounter.toString(),
          'is_last_counter': isLastCounter.toString(),
        });

      // Visit photo is only accepted for first/last counter visits
      if ((isFirstCounter || isLastCounter) && photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('visit_photo', photo.path),
        );
      }



      final streamedResponse = await request.send();


      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        try {
          final decodedResponse = json.decode(response.body);


          return decodedResponse;
        } catch (e) {
          throw Exception('Invalid JSON response: ${response.body}');
        }
      } else {

        throw Exception(
          "Failed to log customer visit. "
          "Status: ${response.statusCode}, "
          "Body: ${response.body}",
        );
      }
    } catch (e) {

      throw Exception("Error logging customer visit: $e");
    }
  }
}
