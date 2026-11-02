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


    try {
      var request = http.Request('POST', Uri.parse(url));

      /// ADD REQUIRED HEADERS
      request.headers.addAll({
        "Content-Type": "application/json",
        if (sid != null) "Cookie": "sid=$sid",
      });


      http.StreamedResponse response = await request.send();
      final responseText = await response.stream.bytesToString();


      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(responseText);
          return result;
        } catch (e) {
          return null;
        }
      } else {
        throw Exception("API call failed");
      }
    } catch (e) {
      return null;
    }
  }
}
