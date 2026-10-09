import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_leave_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Leave applications for the Manager section, using the app's existing
/// `galom.galom.leave_api` endpoints (the Manager API has no leave endpoint).
class ManagerLeaveService {
  ManagerLeaveService({
    http.Client? client,
    Future<String?> Function()? readSid,
    String? baseUrl,
  }) : _client = client,
       _readSid =
           readSid ?? (() => const FlutterSecureStorage().read(key: 'sid')),
       _baseUrl = baseUrl ?? '${ApiConstants.galomBaseUrl}leave_api.';

  final http.Client? _client;
  final Future<String?> Function() _readSid;
  final String _baseUrl;

  Future<List<LeaveApplication>> getLeaveApplications() async {
    final message = await _send('get_leave_application');
    final status = asString(message['status']).toLowerCase();
    if (status != 'success') {
      throw ManagerApiException(
        asStringOrNull(message['message']) ??
            'Could not load leave applications.',
      );
    }
    return asMapList(
      message['applications'],
    ).map(LeaveApplication.fromJson).toList();
  }

  Future<void> approve(String name) =>
      _send('approve_leave_application', docname: name, post: true);

  Future<void> reject(String name) =>
      _send('reject_leave_application', docname: name, post: true);

  /// Returns Frappe's `message` object; throws [ManagerApiException] with a
  /// readable message on any failure.
  Future<Map<String, dynamic>> _send(
    String method, {
    String? docname,
    bool post = false,
  }) async {
    final sid = await _readSid();
    if (sid == null || sid.isEmpty) {
      throw const ManagerApiException(
        ManagerService.sessionExpiredMessage,
        statusCode: 401,
        isSessionExpired: true,
      );
    }
    final uri = Uri.parse(
      '$_baseUrl$method',
    ).replace(queryParameters: docname == null ? null : {'docname': docname});
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cookie': 'sid=$sid',
    };

    http.Response res;
    try {
      final c = _client;
      final future = post
          ? (c != null
                ? c.post(uri, headers: headers)
                : http.post(uri, headers: headers))
          : (c != null
                ? c.get(uri, headers: headers)
                : http.get(uri, headers: headers));
      res = await future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ManagerApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      debugPrint('Leave API [$method] network error: $e');
      throw const ManagerApiException(
        'Unable to reach the server. Check your internet connection.',
      );
    }
    return parseResponse(res.statusCode, res.body);
  }

  @visibleForTesting
  static Map<String, dynamic> parseResponse(int statusCode, String rawBody) {
    dynamic body;
    try {
      body = rawBody.isEmpty ? null : jsonDecode(rawBody);
    } on FormatException {
      body = null;
    }
    final message = body is Map ? body['message'] : null;

    if (statusCode == 200 && body is Map) {
      if (message is Map) {
        final m = asMap(message);
        if (asString(m['status']).toLowerCase() == 'error') {
          throw ManagerApiException(
            asStringOrNull(m['message']) ?? 'The request failed.',
          );
        }
        return m;
      }
      return <String, dynamic>{};
    }

    if (statusCode == 401 || statusCode == 403) {
      final serverMsg = _serverMessage(body);
      // A permission error on approve/reject is not an expired session.
      if (statusCode == 403 && serverMsg != null) {
        throw ManagerApiException(serverMsg, statusCode: 403);
      }
      throw ManagerApiException(
        ManagerService.sessionExpiredMessage,
        statusCode: statusCode,
        isSessionExpired: true,
      );
    }
    throw ManagerApiException(
      _serverMessage(body) ??
          (statusCode >= 500
              ? 'Server error. Please try again.'
              : 'Request failed ($statusCode).'),
      statusCode: statusCode,
    );
  }

  /// Reads Frappe's `_server_messages` (a JSON list of JSON strings).
  static String? _serverMessage(dynamic body) {
    if (body is! Map) return null;
    final raw = body['_server_messages'];
    if (raw is String) {
      try {
        final list = jsonDecode(raw);
        if (list is List && list.isNotEmpty) {
          final first = list.first;
          final decoded = first is String ? jsonDecode(first) : first;
          final msg = decoded is Map
              ? asStringOrNull(decoded['message'])
              : null;
          if (msg != null) return msg.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      } catch (_) {}
    }
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return null;
  }
}
