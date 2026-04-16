// services/create_leave_application_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CreateLeaveApplicationService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final String url =
      'https://uat-mettaapp.tbo365.cloud/api/method/galom.galom.leave_api.create_leave_application';

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

      if (sid == null || sid.isEmpty) {
        throw Exception('SID token not found in secure storage');
      }

      final body = {
        "employee": employee,
        "leave_type": leaveType,
        "from_date": fromDate,
        "to_date": toDate,
        "description": description,
        "half_day": halfDay,
        "half_day_date": halfDayDate,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $sid',
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create leave application: ${response.body}');
      }
    } catch (e) {
      return null;
    }
  }
}
