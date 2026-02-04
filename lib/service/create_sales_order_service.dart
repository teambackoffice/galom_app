import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class CreateSalesOrderService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}create_sales_order';

  Future<Map<String, dynamic>> createSalesOrder({
    required String customer,
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) throw Exception("Session expired. Please log in again.");

      final salesPerson = await _secureStorage.read(key: 'sales_person_id');
      if (salesPerson == null)
        throw Exception("Sales person not found. Please contact admin.");

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      var body = json.encode({
        "customer": customer,
        "delivery_date": deliveryDate,
        "sales_person": salesPerson,
        "items": items,
      });

      print("📤 Request URL: $url");
      print("📤 Request Headers: $headers");
      print("📤 Request Body: $body");

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Raw Response Body: ${response.body}");
      print("📥 Response Headers: ${response.headers}");

      Map<String, dynamic>? decoded;
      try {
        decoded = json.decode(response.body);
        print("📦 Decoded JSON: $decoded");
      } catch (e) {
        print("⚠️ JSON Decode Failed: $e");
      }

      if (response.statusCode == 200) {
        print("✅ SUCCESS FULL RESPONSE RETURNED");
        return decoded ?? {"response": response.body};
      } else {
        final friendlyMessage = _mapErrorMessage(response.body);
        print("❌ ERROR FULL RESPONSE RETURNED");
        print("❗ Friendly Error: $friendlyMessage");
        throw Exception(friendlyMessage);
      }
    } on TimeoutException catch (e) {
      print("⏳ TIMEOUT ERROR: $e");
      throw Exception("Request timed out. Please try again.");
    } on SocketException catch (e) {
      print("🌐 NETWORK ERROR: $e");
      throw Exception("No internet connection. Please check your network.");
    } on FormatException catch (e) {
      print("⚠️ FORMAT ERROR: $e");
      throw Exception("Invalid server response.");
    } catch (e) {
      print("🔥 UNKNOWN ERROR: $e");
      rethrow;
    }
  }

  /// Convert server error body into friendly message
  String _mapErrorMessage(String responseBody) {
    try {
      final decoded = json.decode(responseBody);

      if (decoded is Map<String, dynamic> && decoded.containsKey("message")) {
        final msg = decoded["message"].toString().toLowerCase();

        if (msg.contains("customer")) return "Invalid customer selected.";
        if (msg.contains("date")) return "Invalid delivery date.";
        if (msg.contains("item")) return "One or more items are invalid.";
        if (msg.contains("not allowed")) {
          return "You don’t have permission to perform this action.";
        }
        return decoded["message"].toString();
      }
      return "Unexpected server error.";
    } catch (e) {
      return "Server error. Please try again later.";
    }
  }
}
