import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Signed-in user details already saved by the login flow.
/// The session id is deliberately not exposed here.
class ManagerProfile {
  final String fullName;
  final String? email;
  final String? employeeId;
  final String? employeeName;
  final String? branch;
  final String? roleProfile;
  final String? salesPersonId;
  final List<String> roles;

  const ManagerProfile({
    required this.fullName,
    this.email,
    this.employeeId,
    this.employeeName,
    this.branch,
    this.roleProfile,
    this.salesPersonId,
    this.roles = const [],
  });

  /// Display name: full name, else employee name, else a neutral fallback.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (employeeName != null && employeeName!.trim().isNotEmpty) {
      return employeeName!.trim();
    }
    return 'Manager';
  }

  String get firstName => displayName.split(RegExp(r'\s+')).first;

  /// Managers may log in without the Sales Person role.
  bool get isAlsoSalesPerson => salesPersonId != null;
}

class ManagerProfileController with ChangeNotifier {
  ManagerProfileController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  ManagerProfile? _profile;
  bool _loading = false;

  ManagerProfile? get profile => _profile;

  Future<void> ensureLoaded() async {
    if (_profile != null || _loading) return;
    _loading = true;
    String? clean(String? v) =>
        v == null || v.trim().isEmpty || v == 'null' ? null : v.trim();
    try {
      final all = await _storage.readAll();
      List<String> roles = const [];
      final rawRoles = all['roles'];
      if (rawRoles != null) {
        final decoded = jsonDecode(rawRoles);
        if (decoded is List) roles = decoded.map((e) => e.toString()).toList();
      }
      _profile = ManagerProfile(
        fullName: clean(all['full_name']) ?? '',
        email: clean(all['email']),
        employeeId: clean(all['employee_id']),
        employeeName: clean(all['employee_name']),
        branch: clean(all['branch']),
        roleProfile: clean(all['role_profile']),
        salesPersonId: clean(all['sales_person_id']),
        roles: roles,
      );
    } catch (e) {
      debugPrint('Could not read profile: $e');
      _profile = const ManagerProfile(fullName: '');
    }
    _loading = false;
    notifyListeners();
  }
}
