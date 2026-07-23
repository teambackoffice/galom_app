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

      // ================= REQUEST =================
      print("========== GET MODE OF PAYMENT ==========");
      print("URL: $uri");
      print("SID: $sid");
      print("Headers:");
      print({'Content-Type': 'application/json', 'Cookie': 'sid=$sid'});
      print("=========================================");
      // ===========================================

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      // ================= RESPONSE =================
      print("========== API RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Reason Phrase: ${response.reasonPhrase}");
      print("Response Headers:");
      print(response.headers);
      print("Response Body:");
      print(response.body);
      print("==================================");
      // ============================================

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);

          print("========== PARSED JSON ==========");
          print(const JsonEncoder.withIndent('  ').convert(decoded));
          print("=================================");

          return modeOfPaymentModalFromJson(response.body);
        } catch (e, stackTrace) {
          print("========== JSON PARSE ERROR ==========");
          print("Error: $e");
          print("StackTrace:");
          print(stackTrace);
          print("======================================");

          throw Exception('Failed to parse response: $e');
        }
      } else {
        print("========== HTTP ERROR ==========");
        print("Status Code: ${response.statusCode}");
        print("Reason Phrase: ${response.reasonPhrase}");
        print("Response Body:");
        print(response.body);
        print("================================");

        throw Exception(
          'Failed to load mode of payment. Code: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print("========== EXCEPTION ==========");
      print("Error: $e");
      print("Type: ${e.runtimeType}");
      print("StackTrace:");
      print(stackTrace);
      print("================================");

      rethrow;
    }
  }
}
