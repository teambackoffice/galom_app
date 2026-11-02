import 'package:location_tracker_app/config/api_constant.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/modal/admin_leaves_modal.dart';

class GetAdminLeaveApplicationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AdminLeaveApplicationModalClassResponse?>
  getLeaveApplications() async {
    try {
      final sid = await _storage.read(key: 'sid');

      final url = Uri.parse(
        '${ApiConstants.galomBaseUrl}leave_api.get_leave_application',
      );

      final headers = {'Authorization': 'token $sid', 'Cookie': 'sid=$sid'};


      final response = await http.get(url, headers: headers);


      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);


        final model = AdminLeaveApplicationModalClassResponse.fromJson(decoded);


        return model;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
