// services/leave_application_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/modal/leave_applicatrion_modal.dart';

class GetLeaveApplicationService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final String url =
      'https://uat-mettaapp.tbo365.cloud/api/method/galom.galom.leave_api.get_leave_applications';

  Future<LeaveApplicationModalClass?> getLeaveApplications() async {
    try {
      final sid = await _secureStorage.read(key: 'sid');

      if (sid == null || sid.isEmpty) {
        throw Exception('SID token not found in secure storage');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $sid',
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      print('Leave API URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeaveApplicationModalClass.fromJson(jsonData);
      } else {
        print('Error: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Leave Application Service Error: $e');
      return null;
    }
  }
}
