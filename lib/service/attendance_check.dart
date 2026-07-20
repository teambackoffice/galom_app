import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AttendanceService {
  static const String _baseModule =
      'https://uat-mettaapp.tbo365.cloud/api/method/galom.galom.attendance_api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'sid');
  Future<String?> _employeeId() => _storage.read(key: 'employee_id');

  void _log(String title, dynamic data) {}

  // ─────────────────────────────────────────────────────────────
  // GET EMPLOYEE STATUS
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getEmployeeStatus() async {
    final sid = await _token();
    final employeeId = await _employeeId();

    if (sid == null || employeeId == null) {
      throw Exception('Session expired. Please login again.');
    }

    final uri = Uri.parse(
      '$_baseModule.get_employee_status?employee=$employeeId',
    );

    final headers = {
      'Authorization': 'token $sid',
      'Content-Type': 'application/json',
      'Cookie': 'sid=$sid',
    };

    try {
      final response = await http.get(uri, headers: headers);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Unknown Error');
      }
    } catch (e, stackTrace) {
      _log("ERROR", e);
      _log("STACKTRACE", stackTrace);

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ADD CHECK IN / CHECK OUT
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addCheckIn({
    required String logType,
    required String customKilometer,
    double? latitude,
    double? longitude,
    String? imageBase64,
    String? imageFileName,
  }) async {
    final sid = await _token();
    final employeeId = await _employeeId();

    if (sid == null || employeeId == null) {
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
      };
    }

    final uri = Uri.parse('$_baseModule.add_employee_checkin');

    final headers = {
      'Authorization': 'token $sid',
      'Content-Type': 'application/json',
      'Cookie': 'sid=$sid',
    };

    final body = {
      "employee": employeeId,
      "log_type": logType,
      if (latitude != null) "latitude": latitude.toString(),
      if (longitude != null) "longitude": longitude.toString(),
      "custom_kilometer": customKilometer,
      if (imageBase64 != null) "image_b64": imageBase64,
      if (imageFileName != null) "image_filename": imageFileName,
    };

    _log("REQUEST URL", uri.toString());
    _log("REQUEST METHOD", "POST");
    _log("REQUEST HEADERS", headers);
    _log("REQUEST BODY", const JsonEncoder.withIndent('  ').convert(body));

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      _log("STATUS CODE", response.statusCode);
      _log("RESPONSE HEADERS", response.headers);
      _log("RAW RESPONSE", response.body);

      final decoded = jsonDecode(response.body);

      _log(
        "DECODED RESPONSE",
        const JsonEncoder.withIndent('  ').convert(decoded),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      }

      return {
        'success': false,
        'message': decoded['message'] ?? 'Something went wrong',
        'data': decoded,
      };
    } catch (e, stackTrace) {
      _log("ERROR", e);
      _log("STACKTRACE", stackTrace);

      return {'success': false, 'message': e.toString()};
    }
  }
}
