import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/my_target_modal.dart';

class MyTargetService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url = '${ApiConstants.targetsBaseUrl}get_my_monthly_target';

  /// [month] is `YYYY-MM`; the server defaults to the current month if null.
  Future<MyTargetModal> getMyMonthlyTarget({String? month}) async {
    final String? sid = await _secureStorage.read(key: 'sid');
    if (sid == null || sid.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final uri = Uri.parse(url).replace(
      queryParameters: month != null ? {'month': month} : null,
    );

    final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );
    } catch (e) {
      print('[MyTarget] GET $uri failed: $e');
      throw Exception('Network error. Please check your connection.');
    }

    print('[MyTarget] GET $uri');
    print('[MyTarget] Status: ${response.statusCode}');
    // print() truncates long lines on Android, so print the body in chunks.
    final raw = response.body;
    for (var i = 0; i < raw.length; i += 800) {
      print('[MyTarget] ${raw.substring(i, i + 800 > raw.length ? raw.length : i + 800)}');
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode == 200 &&
        body is Map &&
        body['success'] == true &&
        body['data'] is Map) {
      return MyTargetModal.fromJson(Map<String, dynamic>.from(body['data']));
    }

    final message = body is Map ? body['message'] : null;
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
