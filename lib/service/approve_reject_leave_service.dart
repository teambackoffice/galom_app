import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_constant.dart';

class LeaveApprovalRejectService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> approveLeave({required String docName}) async {
    try {
      final sid = await _storage.read(key: 'sid');

      final url = Uri.parse(
        'https://metta.tbo365.cloud/api/method/galom.galom.leave_api.approve_leave_application?docname=$docName',
      );

      final headers = {
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      headers.forEach((key, value) {});

      final response = await http.post(url, headers: headers);

      response.headers.forEach((key, value) {});

      final decoded = jsonDecode(response.body);

      return decoded;
    } catch (e, stackTrace) {
      return {"status": "error", "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectLeave({required String docName}) async {
    try {
      final sid = await _storage.read(key: 'sid');

      final url = Uri.parse(
        'https://metta.tbo365.cloud/api/method/galom.galom.leave_api.reject_leave_application?docname=$docName',
      );

      final headers = {
        'Cookie': 'sid=$sid',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      headers.forEach((key, value) {});

      final response = await http.post(url, headers: headers);

      response.headers.forEach((key, value) {});

      final decoded = jsonDecode(response.body);

      return decoded;
    } catch (e, stackTrace) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
