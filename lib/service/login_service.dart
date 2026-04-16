// services/auth_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class LoginService {
  final String baseUrl = '${ApiConstants.baseUrl}user_login';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    final sid = await _secureStorage.read(key: 'sid');
    return sid != null && sid.isNotEmpty;
  }

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl?usr=$username&pwd=$password');

    try {
      debugPrint('========== LOGIN API REQUEST ==========');
      debugPrint('URL: $url');
      debugPrint('Username: $username');
      debugPrint('=======================================');

      final response = await http.post(url);

      debugPrint('========== LOGIN API RESPONSE ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        debugPrint('Parsed Response Data: $responseData');

        final fullName = responseData['full_name'];
        final message = responseData['message'];

        debugPrint('Message Object: $message');

        final apiKey = message['api_key'];
        final sid = message['sid'];
        final branch = message['branch'];
        final roles = message['roles'];
        final email = message['email'];
        final empId = message['employee_id'];
        final empName = message['employee_name'];
        final salesPersonId = message['sales_person_id'];

        debugPrint('========== EXTRACTED VALUES ==========');
        debugPrint('Full Name: $fullName');
        debugPrint('API Key: $apiKey');
        debugPrint('SID: $sid');
        debugPrint('Branch: $branch');
        debugPrint('Roles: $roles');
        debugPrint('Email: $email');
        debugPrint('Employee ID: $empId');
        debugPrint('Employee Name: $empName');
        debugPrint('Sales Person ID: $salesPersonId');
        debugPrint('======================================');

        // Store values in secure storage
        await _secureStorage.write(key: 'full_name', value: fullName);
        await _secureStorage.write(key: 'api_key', value: apiKey);
        await _secureStorage.write(key: 'sid', value: sid);
        await _secureStorage.write(key: 'branch', value: branch);
        await _secureStorage.write(key: 'email', value: email);
        await _secureStorage.write(key: 'employee_id', value: empId);
        await _secureStorage.write(key: 'employee_name', value: empName);
        await _secureStorage.write(
          key: 'sales_person_id',
          value: salesPersonId,
        );
        await _secureStorage.write(key: 'roles', value: jsonEncode(roles));

        debugPrint('========== STORAGE SUCCESS ==========');
        debugPrint('All values stored successfully');
        debugPrint('=====================================');

        return message['success_key'] == 1;
      } else {
        debugPrint('========== LOGIN FAILED ==========');
        debugPrint('Reason: Non-200 status code');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('==================================');

        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('========== LOGIN EXCEPTION ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=====================================');

      return false;
    }
  }

  Future<String?> getFullName() async {
    try {
      final name = await _secureStorage.read(key: 'full_name');
      debugPrint('Retrieved Full Name: $name');
      return name;
    } catch (e) {
      debugPrint('Error reading full_name: $e');
      return null;
    }
  }

  Future<String?> getApiKey() async {
    try {
      final key = await _secureStorage.read(key: 'api_key');
      debugPrint('Retrieved API Key: $key');
      return key;
    } catch (e) {
      debugPrint('Error reading api_key: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('========== LOGOUT ==========');
      await _secureStorage.deleteAll();
      debugPrint('All secure storage data deleted');
      debugPrint('============================');
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }
}
