import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CreateLeaveApplicationService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final String url =
      'https://metta.tbo365.cloud/api/method/galom.galom.leave_api.create_leave_application';

  Future<Map<String, dynamic>?> createLeaveApplication({
    required String employee,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String description,
    required int halfDay,
    String? halfDayDate,
  }) async {
    try {
      final sid = await _secureStorage.read(key: 'sid');

      developer.log('========== CREATE LEAVE APPLICATION API ==========');
      developer.log('URL: $url');
      developer.log('SID: $sid');

      if (sid == null || sid.isEmpty) {
        developer.log('❌ SID token not found in secure storage');
        throw Exception('SID token not found in secure storage');
      }

      final headers = {
        'Authorization': 'token $sid',
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sid',
      };

      final body = {
        "employee": employee,
        "leave_type": leaveType,
        "from_date": fromDate,
        "to_date": toDate,
        "description": description,
        "half_day": halfDay,
        "half_day_date": halfDayDate,
      };

      developer.log('Request Headers:\n${jsonEncode(headers)}');
      developer.log(
        'Request Body:\n${const JsonEncoder.withIndent('  ').convert(body)}',
      );

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      developer.log('Status Code: ${response.statusCode}');
      developer.log('Response Headers:\n${jsonEncode(response.headers)}');
      developer.log('Raw Response Body:\n${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        developer.log(
          'Formatted Response:\n${const JsonEncoder.withIndent('  ').convert(jsonData)}',
        );

        developer.log('========== API SUCCESS ==========');

        return jsonData;
      } else {
        developer.log(
          '❌ API FAILED\n'
          'Status Code: ${response.statusCode}\n'
          'Response Body: ${response.body}',
        );

        throw Exception('Failed to create leave application: ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Exception: $e', stackTrace: stackTrace);
      return null;
    }
  }
}
