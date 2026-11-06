// services/auth_service.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class LoginService {
  final String baseUrl = '${ApiConstants.baseUrl}user_login';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    try {
      final sid = await _secureStorage.read(key: 'sid');
      return sid != null && sid.isNotEmpty;
    } catch (e) {
      // Stored data can become undecryptable (e.g. restored from backup after
      // reinstall). Wipe it so the user can log in again instead of hanging.
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl?usr=$username&pwd=$password');

    try {

      final response = await http.post(url);


      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);


        final fullName = responseData['full_name'];
        final message = responseData['message'];


        final apiKey = message['api_key'];
        final sid = message['sid'];
        final branch = message['branch'];
        final roles = message['roles'];
        final email = message['email'];
        final empId = message['employee_id'];
        final empName = message['employee_name'];
        final salesPersonId = message['sales_person_id'];
        final roleProfile = message['role_profile_name'];


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
        await _secureStorage.write(key: 'role_profile', value: roleProfile);
        await _secureStorage.write(key: 'roles', value: jsonEncode(roles));
        // Hint only; get_manager_access stays the source of truth.
        await _secureStorage.write(
          key: 'is_manager',
          value:
              message['is_manager'] == true ||
                  roleProfile?.toString().trim().toUpperCase() == 'ADMIN'
              ? '1'
              : '0',
        );


        return message['success_key'] == 1;
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  Future<String?> getFullName() async {
    try {
      final name = await _secureStorage.read(key: 'full_name');
      return name;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getApiKey() async {
    try {
      final key = await _secureStorage.read(key: 'api_key');
      return key;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getRoles() async {
    try {
      final storedRoles = await _secureStorage.read(key: 'roles');
      if (storedRoles != null) {
        final List decoded = jsonDecode(storedRoles);
        return decoded.map((role) => role.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> getRoleProfile() async {
    try {
      final roleProfile = await _secureStorage.read(key: 'role_profile');
      return roleProfile;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
