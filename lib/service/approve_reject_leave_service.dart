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

      print("\n================ APPROVE REQUEST ================");
      print("URL : $url");
      print("Doc Name : $docName");
      print("SID : $sid");

      print("\nRequest Headers:");
      headers.forEach((key, value) {
        print("$key : $value");
      });

      final response = await http.post(url, headers: headers);

      print("\nStatus Code : ${response.statusCode}");

      print("\nResponse Headers:");
      response.headers.forEach((key, value) {
        print("$key : $value");
      });

      print("\nRaw Response:");
      print(response.body);

      final decoded = jsonDecode(response.body);

      print("\nDecoded Response:");
      print(const JsonEncoder.withIndent('  ').convert(decoded));

      print("=================================================\n");

      return decoded;
    } catch (e, stackTrace) {
      print("=============== APPROVE ERROR =================");
      print(e);
      print(stackTrace);

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

      print("\n================ REJECT REQUEST ================");
      print("URL : $url");
      print("Doc Name : $docName");
      print("SID : $sid");

      print("\nRequest Headers:");
      headers.forEach((key, value) {
        print("$key : $value");
      });

      final response = await http.post(url, headers: headers);

      print("\nStatus Code : ${response.statusCode}");

      print("\nResponse Headers:");
      response.headers.forEach((key, value) {
        print("$key : $value");
      });

      print("\nRaw Response:");
      print(response.body);

      final decoded = jsonDecode(response.body);

      print("\nDecoded Response:");
      print(const JsonEncoder.withIndent('  ').convert(decoded));

      print("=================================================\n");

      return decoded;
    } catch (e, stackTrace) {
      print("=============== REJECT ERROR =================");
      print(e);
      print(stackTrace);

      return {"status": "error", "message": e.toString()};
    }
  }
}
