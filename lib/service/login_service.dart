// services/auth_service.dart
import 'dart:convert';

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
      final response = await http.post(url);

      if (response.statusCode == 200) {
        print("url: $url");
        print(response.body);
        final responseData = jsonDecode(response.body);

        final fullName = responseData['full_name'];
        final message = responseData['message'];
        final apiKey = message['api_key'];
        final sid = message['sid'];
        final branch = message['branch'];
        final roles = message['roles'];
        final email = message['email'];
        final empId = message['emp_id'];
        final empName = message['emp_name'];
        final salesPersonId = message['sales_person_id'];

        // Store values in secure storage
        await _secureStorage.write(key: 'full_name', value: fullName);
        await _secureStorage.write(key: 'api_key', value: apiKey);
        await _secureStorage.write(key: 'sid', value: sid);
        await _secureStorage.write(key: "branch", value: branch);
        await _secureStorage.write(key: 'email', value: email);
        await _secureStorage.write(key: 'employee_id', value: empId);
        await _secureStorage.write(key: 'employee_name', value: empName);
        await _secureStorage.write(
          key: 'sales_person_id',
          value: salesPersonId,
        );

        await _secureStorage.write(key: 'roles', value: jsonEncode(roles));

        return message['success_key'] == 1;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String?> getFullName() async {
    final name = await _secureStorage.read(key: 'full_name');
    return name;
  }

  Future<String?> getApiKey() async {
    final key = await _secureStorage.read(key: 'api_key');
    return key;
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}
