import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/modal/leave_type_modal.dart';

class LeaveTypesService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url =
      'https://metta.tbo365.cloud/api/method/galom.galom.leave_api.get_leave_types';

  Future<LeaveTypesResponse?> getLeaveTypes() async {
    try {
      final sid = await _secureStorage.read(key: 'sid');

      if (sid == null || sid.isEmpty) {
        return null;
      }

      final headers = {
        'Authorization': 'token $sid',
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sid',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LeaveTypesResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      return null;
    }
  }
}
