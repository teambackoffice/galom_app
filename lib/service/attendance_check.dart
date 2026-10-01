import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class AttendanceService {
  static const String _baseModule =
      '${ApiConstants.galomBaseUrl}attendance_api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'sid');
  Future<String?> _employeeId() => _storage.read(key: 'employee_id');

  // ─────────────────────────────────────────────────────────────
  // PRINT LOG
  // ─────────────────────────────────────────────────────────────
  void _log(String title, dynamic data) {
    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔵 $title');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('$data');
  }

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

    // REQUEST
    _log('GET EMPLOYEE STATUS - REQUEST URL', uri.toString());
    _log('GET EMPLOYEE STATUS - METHOD', 'GET');
    _log(
      'GET EMPLOYEE STATUS - HEADERS',
      const JsonEncoder.withIndent('  ').convert(headers),
    );

    try {
      final response = await http.get(uri, headers: headers);

      // RESPONSE
      _log('GET EMPLOYEE STATUS - STATUS CODE', response.statusCode);

      _log(
        'GET EMPLOYEE STATUS - RESPONSE HEADERS',
        const JsonEncoder.withIndent('  ').convert(response.headers),
      );

      _log('GET EMPLOYEE STATUS - RAW RESPONSE', response.body);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);

        _log(
          'GET EMPLOYEE STATUS - DECODED RESPONSE',
          const JsonEncoder.withIndent('  ').convert(decoded),
        );
      } catch (e) {
        _log('GET EMPLOYEE STATUS - JSON DECODE ERROR', e.toString());
      }

      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(
          decoded is Map
              ? decoded['message'] ?? 'Unknown Error'
              : 'Unknown Error',
        );
      }
    } catch (e, stackTrace) {
      _log('GET EMPLOYEE STATUS - ERROR', e.toString());
      _log('GET EMPLOYEE STATUS - STACKTRACE', stackTrace.toString());

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
      _log('ADD CHECK IN - SESSION ERROR', 'SID or Employee ID is missing');

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
      'employee': employeeId,
      'log_type': logType,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      'custom_kilometer': customKilometer,
      if (imageBase64 != null) 'image_b64': imageBase64,
      if (imageFileName != null) 'image_filename': imageFileName,
    };

    // REQUEST
    _log('ADD CHECK IN - REQUEST URL', uri.toString());
    _log('ADD CHECK IN - METHOD', 'POST');

    _log(
      'ADD CHECK IN - HEADERS',
      const JsonEncoder.withIndent('  ').convert(headers),
    );

    _log(
      'ADD CHECK IN - REQUEST BODY',
      const JsonEncoder.withIndent('  ').convert(body),
    );

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      // RESPONSE
      _log('ADD CHECK IN - STATUS CODE', response.statusCode);

      _log(
        'ADD CHECK IN - RESPONSE HEADERS',
        const JsonEncoder.withIndent('  ').convert(response.headers),
      );

      _log('ADD CHECK IN - RAW RESPONSE', response.body);

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);

        _log(
          'ADD CHECK IN - DECODED RESPONSE',
          const JsonEncoder.withIndent('  ').convert(decoded),
        );
      } catch (e) {
        _log('ADD CHECK IN - JSON DECODE ERROR', e.toString());
      }

      // SUCCESS
      if (response.statusCode == 200) {
        _log(
          'ADD CHECK IN - SUCCESS',
          'Check-in/check-out API completed successfully',
        );

        return {'success': true, 'data': decoded};
      }

      // API ERROR
      final message = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';

      _log('ADD CHECK IN - API ERROR', message);

      return {'success': false, 'message': message, 'data': decoded};
    } catch (e, stackTrace) {
      _log('ADD CHECK IN - EXCEPTION', e.toString());

      _log('ADD CHECK IN - STACKTRACE', stackTrace.toString());

      return {'success': false, 'message': e.toString()};
    }
  }
}
