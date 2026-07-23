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
        'https://metta.tbo365.cloud/api/method/galom.galom.leave_api.get_leave_application',
      );

      final headers = {'Authorization': 'token $sid', 'Cookie': 'sid=$sid'};

      print("========== GET ADMIN LEAVE APPLICATION ==========");
      print("URL: $url");
      print("Headers: $headers");

      final response = await http.get(url, headers: headers);

      print("Status Code: ${response.statusCode}");
      print("Reason: ${response.reasonPhrase}");
      print("Response Headers: ${response.headers}");
      print("Raw Response:");
      print(response.body);
      print("===============================================");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print("Decoded JSON:");
        print(const JsonEncoder.withIndent('  ').convert(decoded));

        final model = AdminLeaveApplicationModalClassResponse.fromJson(decoded);

        print("Model Parsed Successfully");

        return model;
      } else {
        print("API Failed with Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e, stackTrace) {
      print("Exception: $e");
      print("StackTrace:");
      print(stackTrace);
      return null;
    }
  }
}
