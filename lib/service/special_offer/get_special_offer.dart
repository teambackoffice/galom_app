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

    print("📡 API Request Initiated");
    print("➡️ URL: $url");
    print("➡️ Method: GET");

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
            print("⏳ SID not found, retrying... (Attempt ${attempt + 1}/3)");
            await Future.delayed(Duration(milliseconds: 300));
          }
        } catch (e) {
          print("⚠️ Error reading from secure storage: $e");
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 300));
          }
        }
      }

      if (sid == null || sid.isEmpty) {
        print("❌ No SID found after retries - User not authenticated");
        throw Exception("Authentication required");
      }

      print(
        "🔑 Using SID from Secure Storage: ${sid.substring(0, 10)}...",
      ); // Only show first 10 chars for security

      // ✅ Create request with authentication headers
      var request = http.Request('GET', Uri.parse(url));

      request.headers.addAll({
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
      });

      http.StreamedResponse response = await request.send();
      final responseText = await response.stream.bytesToString();

      print("📥 Raw Response Received");
      print("➡️ Status Code: ${response.statusCode}");
      print("➡️ Response Body: $responseText");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(responseText);

          // ✅ Check for Frappe-style error in response body
          if (result['message'] != null &&
              result['message'] is Map &&
              result['message']['status'] == 'error') {
            print("❌ API returned error: ${result['message']['message']}");
            throw Exception(result['message']['message']);
          }

          print("✅ Successfully fetched settings");
          print("📦 Parsed JSON Response:");
          print(result);

          // ✅ EXTRACT AND PRINT THE ACTUAL BOOLEAN VALUE
          if (result['message'] != null && result['message']['data'] != null) {
            final data = result['message']['data'];
            final enableStockValidation = data['enable_stock_validation'];

            print("═══════════════════════════════════════════");
            print("🎯 CURRENT BACKEND VALUE:");
            print("   enable_stock_validation = $enableStockValidation");
            print("   Type: ${enableStockValidation.runtimeType}");
            print("═══════════════════════════════════════════");
            print("🔄 INVERTED LOGIC (for UI switch):");
            print(
              "   Backend = $enableStockValidation → UI Switch = ${!enableStockValidation}",
            );
            print("═══════════════════════════════════════════");
          } else {
            print(
              "⚠️ Warning: Could not find 'enable_stock_validation' in response",
            );
          }

          return result;
        } catch (e) {
          print("❌ JSON Parsing Error: $e");
          rethrow;
        }
      } else {
        print("❌ API Error - Status Code: ${response.statusCode}");
        print("❌ Reason: ${response.reasonPhrase}");
        throw Exception(response.reasonPhrase ?? "API call failed");
      }
    } catch (e) {
      print("🔥 Exception in API Call: $e");
      rethrow;
    }
  }
}
