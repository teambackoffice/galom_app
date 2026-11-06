import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/my_target_modal.dart';

class MyTargetService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final String url = '${ApiConstants.targetsBaseUrl}get_my_monthly_target';

  /// [month] is YYYY-MM; server defaults to current month if null.
  Future<MyTargetModal> getMyMonthlyTarget({String? month}) async {
    print('\n========== MY TARGET API START ==========');

    final String? sid = await _secureStorage.read(key: 'sid');

    print(
      '🔑 SESSION ID: ${sid != null && sid.isNotEmpty ? "Available" : "Not Found"}',
    );
    print('📅 REQUESTED MONTH: ${month ?? "Current Month"}');

    if (sid == null || sid.isEmpty) {
      print('❌ ERROR: Session ID not found');
      throw Exception('Session expired. Please login again.');
    }

    final uri = Uri.parse(
      url,
    ).replace(queryParameters: month != null ? {'month': month} : null);

    print('\n➡️ REQUEST URL: $uri');
    print('➡️ REQUEST METHOD: GET');
    print('➡️ REQUEST HEADERS:');
    print({'Content-Type': 'application/json', 'Cookie': 'sid=********'});

    final http.Response response;

    try {
      response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );

      print('\n========== API RESPONSE ==========');

      print('📥 STATUS CODE: ${response.statusCode}');
      print('📥 REASON PHRASE: ${response.reasonPhrase}');

      print('\n📥 RESPONSE HEADERS:');
      response.headers.forEach((key, value) {
        print('$key: $value');
      });

      print('\n📥 RAW RESPONSE BODY:');
      print(response.body);

      print('\n========== DECODED RESPONSE ==========');
    } catch (e, stackTrace) {
      print('❌ NETWORK ERROR: $e');
      print('❌ STACK TRACE: $stackTrace');

      throw Exception('Network error. Please check your connection.');
    }

    dynamic body;

    try {
      body = jsonDecode(response.body);

      print(const JsonEncoder.withIndent('  ').convert(body));
    } catch (e) {
      body = null;
      print('❌ JSON DECODING ERROR: $e');
    }

    print('\n========== RESPONSE PROCESSING ==========');

    if (response.statusCode == 200 &&
        body is Map &&
        body['success'] == true &&
        body['data'] is Map) {
      print('✅ API SUCCESS');
      print('📦 DATA:');
      print(body['data']);

      final modal = MyTargetModal.fromJson(
        Map<String, dynamic>.from(body['data']),
      );

      print('✅ MODEL PARSING SUCCESS');
      print('========== MY TARGET API END ==========\n');

      return modal;
    }

    final message = body is Map ? body['message'] : null;

    print('❌ API FAILED');
    print('❌ ERROR MESSAGE: $message');
    print('❌ STATUS CODE: ${response.statusCode}');

    print('========== MY TARGET API END ==========\n');

    if (message is String && message.trim().isNotEmpty) {
      throw Exception(message);
    }

    throw Exception(_messageForStatus(response.statusCode));
  }

  String _messageForStatus(int code) {
    switch (code) {
      case 400:
        return 'Invalid month selected.';
      case 401:
      case 403:
        return 'Session expired. Please login again.';
      case 404:
        return 'Your account is not linked to a Sales Person.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return 'Failed to load target. Code: $code';
    }
  }
}
