// services/special_offer_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class GetSpecialOfferService {
  // ✅ Initialize secure storage
  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> getChundakadanSettings() async {
    final String url = '${ApiConstants.baseUrl}get_chundakadan_settings';


    try {
      // ✅ Get SID from secure storage with retry logic
      String? sid;

      // Try up to 3 times with small delays
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          sid = await _secureStorage.read(key: 'sid');

          if (sid != null && sid.isNotEmpty) {
            break; // SID found, exit retry loop
          }

          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 300));
          }
        } catch (e) {
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 300));
          }
        }
      }

      if (sid == null || sid.isEmpty) {
        throw Exception("Authentication required");
      }


      // ✅ Create request with authentication headers
      var request = http.Request('GET', Uri.parse(url));

      request.headers.addAll({
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
      });

      http.StreamedResponse response = await request.send();
      final responseText = await response.stream.bytesToString();


      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(responseText);

          // ✅ Check for Frappe-style error in response body
          if (result['message'] != null &&
              result['message'] is Map &&
              result['message']['status'] == 'error') {
            throw Exception(result['message']['message']);
          }


          return result;
        } catch (e) {
          rethrow;
        }
      } else {
        throw Exception(response.reasonPhrase ?? "API call failed");
      }
    } catch (e) {
      rethrow;
    }
  }
}
