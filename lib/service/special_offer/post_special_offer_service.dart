import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class SpecialOfferService {
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> updateSpecialOfferSettings({
    required bool enableStockValidation,
  }) async {
    final String url =
        '${ApiConstants.baseUrl}update_chundakadan_settings?enable_stock_validation=$enableStockValidation';

    final String? sid = await storage.read(key: "sid");

    print("📡 API Request Initiated");
    print("➡️ URL: $url");

    try {
      var request = http.Request('POST', Uri.parse(url));

      /// ADD REQUIRED HEADERS
      request.headers.addAll({
        "Content-Type": "application/json",
        if (sid != null) "Cookie": "sid=$sid",
      });

      print("➡️ Headers Sent: ${request.headers}");

      http.StreamedResponse response = await request.send();
      final responseText = await response.stream.bytesToString();

      print("📥 Raw Response Received");
      print("➡️ Status Code: ${response.statusCode}");
      print("➡️ Response Body: $responseText");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(responseText);
          return result;
        } catch (e) {
          print("❌ JSON Parsing Error: $e");
          return null;
        }
      } else {
        print("❌ API Error - Status Code: ${response.statusCode}");
        throw Exception("API call failed");
      }
    } catch (e) {
      print("🔥 Exception in API Call: $e");
      return null;
    }
  }
}
