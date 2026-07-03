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
        'https://uat-mettaapp.tbo365.cloud/api/method/galom.galom.leave_api.get_leave_application',
      );

      final headers = {'Authorization': 'token $sid', 'Cookie': 'sid=$sid'};

      // Request Logs
      print("========================================");
      print("GET LEAVE APPLICATION API");
      print("========================================");
      print("URL:");
      print(url);

      print("\nHeaders:");
      print(headers);

      final response = await http.get(url, headers: headers);

      // Response Logs
      print("\nStatus Code:");
      print(response.statusCode);

      print("\nResponse Headers:");
      print(response.headers);

      print("\nRaw Response:");
      print(response.body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print("\nDecoded JSON:");
        print(const JsonEncoder.withIndent('  ').convert(decoded));

        final model = AdminLeaveApplicationModalClassResponse.fromJson(decoded);

        print("\nParsed Model:");

        print("========================================");

        return model;
      } else {
        print("\nAPI Failed");
        print("Body:");
        print(response.body);
        print("========================================");
      }

      return null;
    } catch (e, stackTrace) {
      print("========================================");
      print("Get Leave Applications Error");
      print(e);
      print("\nStackTrace:");
      print(stackTrace);
      print("========================================");
      return null;
    }
  }
}
