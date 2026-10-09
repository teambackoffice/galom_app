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

      print('================ LOG CUSTOMER VISIT ================');
      print('🚀 API URL: $url');
      print('📅 Date: $date');
      print('⏰ Time: $time');
      print('👤 Customer Name: $customerName');
      print('📝 Description: $description');
      print('📍 Latitude: $latitude');
      print('📍 Longitude: $longitude');
      print('🏁 Is First Counter: $isFirstCounter');
      print('🔚 Is Last Counter: $isLastCounter');
      print('📸 Photo: ${photo?.path ?? "No photo"}');
      print('🍪 SID: ${sid ?? "NULL"}');
      print('====================================================');

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

      print('📤 REQUEST METHOD: ${request.method}');
      print('📤 REQUEST URL: ${request.url}');
      print('📤 REQUEST HEADERS: ${request.headers}');
      print('📤 REQUEST FIELDS: ${request.fields}');
      print(
        '📤 REQUEST FILES: ${request.files.map((file) => {'field': file.field, 'filename': file.filename, 'length': file.length}).toList()}',
      );

      print('📤 Sending request...');

      final streamedResponse = await request.send();

      print('📥 Response received');

      final response = await http.Response.fromStream(streamedResponse);

      print('================ API RESPONSE =====================');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Reason Phrase: ${response.reasonPhrase}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body:');
      print(response.body);
      print('====================================================');

      if (response.statusCode == 200) {
        try {
          final decodedResponse = json.decode(response.body);

          print('✅ Decoded Response:');
          print(decodedResponse);

          return decodedResponse;
        } catch (e) {
          print('❌ JSON Decode Error: $e');
          throw Exception('Invalid JSON response: ${response.body}');
        }
      } else {
        print('❌ API FAILED');
        print('❌ Status: ${response.statusCode}');
        print('❌ Body: ${response.body}');

        throw Exception(
          "Failed to log customer visit. "
          "Status: ${response.statusCode}, "
          "Body: ${response.body}",
        );
      }
    } catch (e, stackTrace) {
      print('====================================================');
      print('❌ ERROR IN LOG CUSTOMER VISIT');
      print('❌ Error: $e');
      print('❌ StackTrace:');
      print(stackTrace);
      print('====================================================');

      throw Exception("Error logging customer visit: $e");
    }
  }
}
