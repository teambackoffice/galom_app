import 'dart:convert';
import 'dart:developer' as developer;

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

      developer.log('========== GET LEAVE APPLICATION API ==========');
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

      developer.log('Request Headers: ${jsonEncode(headers)}');

      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log('Status Code: ${response.statusCode}');
      developer.log('Response Headers: ${jsonEncode(response.headers)}');
      developer.log('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        developer.log(
          'Formatted Response:\n${const JsonEncoder.withIndent('  ').convert(jsonData)}',
        );

        developer.log('========== API SUCCESS ==========');

        return LeaveApplicationModalClass.fromJson(jsonData);
      } else {
        developer.log(
          '❌ API Failed\nStatus Code: ${response.statusCode}\nResponse: ${response.body}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log('❌ Exception: $e', stackTrace: stackTrace);
      return null;
    }
  }
}
