import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class RemarksTaskService {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = ApiConstants.baseUrl; // ✅ keep only base

  /// Update task remarks (naming fixed)
  Future<Map<String, dynamic>?> updateTaskRemarks({
    required String taskName,
    required String remarks,
  }) async {
    return _postRequest(
      endpoint: "add_remarks",
      body: {"task_name": taskName, "remarks": remarks},
    );
  }

  /// Add remarks (alias of updateTaskRemarks)
  Future<Map<String, dynamic>?> addRemarks({
    required String taskName,
    required String remarks,
  }) async {
    return _postRequest(
      endpoint: "add_remarks",
      body: {"task_name": taskName, "remarks": remarks},
    );
  }

  /// 🔹 Common private method to handle POST requests
  Future<Map<String, dynamic>?> _postRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      // Get sid from secure storage
      String? sid = await _storage.read(key: "sid");

      if (sid == null) {
        throw Exception("SID not found in storage. Please login again.");
      }

      var headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

      // ✅ build endpoint correctly
      var url = Uri.parse("$_baseUrl$endpoint");

      var request = http.Request('POST', url);
      request.body = json.encode(body);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String resBody = await response.stream.bytesToString();
        return json.decode(resBody);
      } else {
        throw Exception(
          "Error: ${response.statusCode} ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      return null;
    }
  }
}
