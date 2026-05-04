import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AttendanceService {
  static const String _baseModule =
      'https://uat-mettaapp.tbo365.cloud/api/method/galom.galom.attendance_api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'sid');
  Future<String?> _employeeId() => _storage.read(key: 'employee_id');

  void _log(String title, dynamic data) {
    print('===== $title =====');
    print(data);
    print('======================');
  }

  // ── GET employee status ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getEmployeeStatus() async {
    final sid = await _token();
    final employeeId = await _employeeId();

    if (sid == null || employeeId == null) {
      throw Exception('Session expired. Please login again.');
    }

    final uri = Uri.parse('$_baseModule.get_employee_status?employee=$employeeId');

    _log("REQUEST URL", uri);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'token $sid',
        'Content-Type': 'application/json',
        "Cookie": "sid=$sid",
      },
    );

    _log("STATUS CODE", response.statusCode);
    _log("RAW RESPONSE", response.body);

    final decoded = json.decode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? 'Error');
    }
  }

  // ── POST check-in / check-out ───────────────────────────────────────────────
  Future<Map<String, dynamic>> addCheckIn({required String logType}) async {
    final sid = await _token();
    final employeeId = await _employeeId();

    if (sid == null || employeeId == null) {
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
      };
    }

    final uri = Uri.parse('$_baseModule.add_employee_checkin');
    print("Uri: $uri");

    final body = {'log_type': logType, 'employee': employeeId};

    _log("REQUEST BODY", body);
    print("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'token $sid',
          'Content-Type': 'application/json',
          "Cookie": "sid=$sid", // keep this if backend needs it
        },
        body: jsonEncode(body),
      );

      _log("RAW RESPONSE", response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
