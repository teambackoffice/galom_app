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

      if (sid == null || sid.isEmpty) {
        throw Exception('SID token not found in secure storage');
      }

      final headers = {
        'Authorization': 'token $sid',
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sid',
      };

      final uri = Uri.parse(url);

      // ================= REQUEST =================
      developer.log("========== GET LEAVE APPLICATIONS ==========");
      developer.log("URL: $uri");
      developer.log("SID: $sid");
      developer.log("Headers:");
      developer.log(const JsonEncoder.withIndent('  ').convert(headers));
      developer.log("============================================");
      // ===========================================

      final response = await http.get(uri, headers: headers);

      // ================= RESPONSE =================
      developer.log("========== API RESPONSE ==========");
      developer.log("Status Code: ${response.statusCode}");
      developer.log("Reason Phrase: ${response.reasonPhrase}");
      developer.log("Response Headers:");
      developer.log(
        const JsonEncoder.withIndent('  ').convert(response.headers),
      );
      developer.log("Response Body:");
      developer.log(response.body);
      developer.log("==================================");
      // ============================================

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          developer.log("========== PARSED JSON ==========");
          developer.log(const JsonEncoder.withIndent('  ').convert(jsonData));
          developer.log("=================================");

          return LeaveApplicationModalClass.fromJson(jsonData);
        } catch (e, stackTrace) {
          developer.log("========== JSON PARSE ERROR ==========");
          developer.log("Error: $e");
          developer.log("StackTrace:\n$stackTrace");
          developer.log("======================================");

          return null;
        }
      } else {
        developer.log("========== HTTP ERROR ==========");
        developer.log("Status Code: ${response.statusCode}");
        developer.log("Reason Phrase: ${response.reasonPhrase}");
        developer.log("Response Headers:");
        developer.log(
          const JsonEncoder.withIndent('  ').convert(response.headers),
        );
        developer.log("Response Body:");
        developer.log(response.body);
        developer.log("================================");

        return null;
      }
    } catch (e, stackTrace) {
      developer.log("========== EXCEPTION ==========");
      developer.log("Error: $e");
      developer.log("Type: ${e.runtimeType}");
      developer.log("StackTrace:\n$stackTrace");
      developer.log("================================");

      return null;
    }
  }
}
