import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class UpdateTaskStatus {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = "${ApiConstants.baseUrl}update_status";

  /// Update task status API
  Future<Map<String, dynamic>?> updateTaskStatus({
    required String taskName,
    required String status,
    DateTime? completionDate, // Optional completion date
  }) async {
    try {
      // Get sid from secure storage
      String? sid = await _storage.read(key: "sid");

      if (sid == null) {
        throw Exception("SID not found in storage. Please login again.");
      }

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      var url = Uri.parse(_baseUrl);

      var request = http.Request('POST', url);

      // Build request body
      Map<String, dynamic> requestBody = {
        "task_name": taskName,
        "status": status,
      };

      // Add completion_date only if provided
      if (completionDate != null) {
        requestBody["completion_date"] = completionDate.toIso8601String();
      }

      request.body = json.encode(requestBody);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String resBody = await response.stream.bytesToString();

        var decoded = json.decode(resBody);

        return decoded;
      } else {
        String errorBody = await response.stream.bytesToString();
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
