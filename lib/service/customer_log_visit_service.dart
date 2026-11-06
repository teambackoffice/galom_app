import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';

class LogCustomerVisitService {
  static const _storage = FlutterSecureStorage();
  final String url = '${ApiConstants.baseUrl}log_customer_visit';
  final String updateUrl = '${ApiConstants.baseUrl}update_customer_visit';
  final String todayVisitsUrl = '${ApiConstants.baseUrl}get_my_today_visits';

  Future<String> _requireSid() async {
    final sid = await _storage.read(key: 'sid');
    if (sid == null) {
      throw Exception("Session expired. Please log in again.");
    }
    return sid;
  }

  /// Logs a customer visit (multipart, with optional visit photo).
  /// For first/last counter visits, `time` is the check-in time.
  Future<Map<String, dynamic>> logCustomerVisit({
    required String date,
    required String time,
    required double longitude,
    required double latitude,
    required String customerName,
    required String description,
    File? photo,
    bool isFirstCounter = false,
    bool isLastCounter = false,
  }) async {
    try {
      final sid = await _requireSid();

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Cookie'] = 'sid=$sid'
        ..fields.addAll({
          'customer_name': customerName,
          'description': description,
          'date': date,
          'time': time,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'is_first_counter': isFirstCounter ? '1' : '0',
          'is_last_counter': isLastCounter ? '1' : '0',
        });

      // Visit photo is only accepted for first/last counter visits
      if ((isFirstCounter || isLastCounter) && photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('visit_photo', photo.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw Exception('Invalid JSON response: ${response.body}');
        }
      }
      throw Exception(
        frappeErrorMessage(response.body) ??
            "Failed to log customer visit (status ${response.statusCode})",
      );
    } catch (e) {
      throw Exception("Error logging customer visit: $e");
    }
  }

  /// Closes the meeting at a first/last counter visit. Returns the
  /// `message` payload (name, checkin_time, checkout_time, meeting_remarks).
  Future<Map<String, dynamic>> updateCustomerVisit({
    required String name,
    required String meetingRemarks,
    String? checkoutTime,
  }) async {
    final sid = await _requireSid();
    final response = await http.post(
      Uri.parse(updateUrl),
      headers: {'Cookie': 'sid=$sid', 'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'meeting_remarks': meetingRemarks,
        if (checkoutTime != null) 'checkout_time': checkoutTime,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final message = decoded is Map ? decoded['message'] : null;
      if (message is Map<String, dynamic>) return message;
      throw Exception('Unexpected response: ${response.body}');
    }
    throw Exception(
      frappeErrorMessage(response.body) ??
          'Failed to finish meeting (status ${response.statusCode})',
    );
  }

  /// Today's Customer Visit Log rows for the logged-in sales person.
  Future<List<Map<String, dynamic>>> getMyTodayVisits() async {
    final sid = await _requireSid();
    final response = await http.get(
      Uri.parse(todayVisitsUrl),
      headers: {'Cookie': 'sid=$sid'},
    );

    final decoded = _tryDecode(response.body);
    if (response.statusCode == 200 && decoded is Map) {
      final data = decoded['data'];
      final entries = data is Map ? data['entries'] : null;
      if (entries is List) {
        return entries.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    }
    throw Exception(
      frappeErrorMessage(response.body) ??
          "Failed to load today's visits (status ${response.statusCode})",
    );
  }

  static dynamic _tryDecode(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  /// Pulls a readable message out of a Frappe error body
  /// (`_server_messages`, then `exception`, then a string `message`).
  static String? frappeErrorMessage(String body) {
    final decoded = _tryDecode(body);
    if (decoded is! Map) return null;

    final raw = decoded['_server_messages'];
    if (raw is String) {
      try {
        final list = json.decode(raw);
        if (list is List && list.isNotEmpty) {
          final first = list.first;
          final msg = first is String ? json.decode(first) : first;
          if (msg is Map && msg['message'] is String) {
            return _stripHtml(msg['message'] as String);
          }
        }
      } catch (_) {}
    }

    final exception = decoded['exception'];
    if (exception is String && exception.trim().isNotEmpty) {
      // "frappe.exceptions.ValidationError: Something" -> "Something"
      final idx = exception.indexOf(': ');
      return _stripHtml(idx >= 0 ? exception.substring(idx + 2) : exception);
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return _stripHtml(message);
    }
    return null;
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
