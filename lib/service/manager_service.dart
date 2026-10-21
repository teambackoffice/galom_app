import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_detail_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';

/// Error raised by any Manager API call. [message] is always safe to show.
class ManagerApiException implements Exception {
  final int? statusCode;
  final String message;

  /// True when Frappe rejected the session (401/403 without our envelope).
  final bool isSessionExpired;

  /// True when our endpoint said the user is not a manager (403 + envelope).
  final bool isForbidden;

  const ManagerApiException(
    this.message, {
    this.statusCode,
    this.isSessionExpired = false,
    this.isForbidden = false,
  });

  @override
  String toString() => message;
}

/// Read-only client for `sales_pilot.Api.manager.*`.
class ManagerService {
  ManagerService({
    http.Client? client,
    Future<String?> Function()? readSid,
    String? baseUrl,
  }) : _client = client,
       _readSid = readSid ?? _defaultReadSid,
       _baseUrl = baseUrl ?? ApiConstants.managerBaseUrl;

  final http.Client? _client;
  final Future<String?> Function() _readSid;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 30);
  static const String sessionExpiredMessage =
      'Session expired. Please login again.';

  static Future<String?> _defaultReadSid() =>
      const FlutterSecureStorage().read(key: 'sid');

  /// Session id for authenticated image requests (never shown in the UI).
  Future<String?> readSid() => _readSid();

  Future<Map<String, dynamic>> _get(
    String method, [
    Map<String, String> params = const {},
  ]) async {
    final sid = await _readSid();
    if (sid == null || sid.isEmpty) {
      throw const ManagerApiException(
        sessionExpiredMessage,
        statusCode: 401,
        isSessionExpired: true,
      );
    }

    final uri = Uri.parse(
      '$_baseUrl$method',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

    http.Response res;
    try {
      final future = _client != null
          ? _client.get(uri, headers: headers)
          : http.get(uri, headers: headers);
      res = await future.timeout(_timeout);
    } on TimeoutException {
      throw const ManagerApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ManagerApiException(
        'Unable to reach the server. Check your internet connection.',
      );
    } catch (e) {
      debugPrint('Manager API [$method] network error: $e');
      throw const ManagerApiException(
        'Unable to reach the server. Check your internet connection.',
      );
    }

    return parseEnvelope(res.statusCode, res.body, method: method);
  }

  /// Applies the documented envelope rule: success only when
  /// `statusCode == 200 && body['success'] == true`.
  @visibleForTesting
  static Map<String, dynamic> parseEnvelope(
    int statusCode,
    String rawBody, {
    String method = '',
  }) {
    dynamic body;
    try {
      body = rawBody.isEmpty ? null : jsonDecode(rawBody);
    } on FormatException {
      body = null;
    }

    if (statusCode == 200 && body is Map && body['success'] == true) {
      return asMap(body['data']);
    }

    final hasEnvelope = body is Map && body.containsKey('success');
    final message = body is Map ? body['message'] : null;
    final serverMessage = message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;

    debugPrint('Manager API [$method] failed ($statusCode)');

    if ((statusCode == 401 || statusCode == 403) && !hasEnvelope) {
      throw ManagerApiException(
        sessionExpiredMessage,
        statusCode: statusCode,
        isSessionExpired: true,
      );
    }
    if (statusCode == 403) {
      throw ManagerApiException(
        serverMessage ?? 'You do not have manager access.',
        statusCode: 403,
        isForbidden: true,
      );
    }
    if (serverMessage != null) {
      throw ManagerApiException(serverMessage, statusCode: statusCode);
    }
    throw ManagerApiException(switch (statusCode) {
      200 => 'Unexpected response from the server.',
      400 => 'The request was not valid. Please adjust the filters.',
      404 => 'Record not found.',
      >= 500 => 'Server error. Please try again.',
      _ => 'Request failed ($statusCode).',
    }, statusCode: statusCode);
  }

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------

  Future<bool> getManagerAccess() async {
    final data = await _get('get_manager_access');
    return data['is_manager'] == true;
  }

  Future<List<SalesPerson>> getSalesPersons({
    bool includeDisabled = false,
  }) async {
    final data = await _get('get_sales_persons', {
      'include_disabled': includeDisabled ? '1' : '0',
    });
    return asMapList(data['sales_persons']).map(SalesPerson.fromJson).toList();
  }

  Future<ManagerPage<T>> getList<T>(
    ManagerModule module,
    ManagerQuery query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final data = await _get(module.method, query.toParams());
    return ManagerPage.fromJson(data, parse);
  }

  Future<ManagerPage<AttendanceRecord>> getAttendance(ManagerQuery q) =>
      getList(ManagerModule.attendance, q, AttendanceRecord.fromJson);

  Future<ManagerPage<CustomerVisit>> getCustomerVisits(ManagerQuery q) =>
      getList(ManagerModule.visits, q, CustomerVisit.fromJson);

  Future<ManagerPage<SalesOrderRecord>> getSalesOrders(ManagerQuery q) =>
      getList(ManagerModule.salesOrders, q, SalesOrderRecord.fromJson);

  Future<ManagerPage<SalesReturnRecord>> getSalesReturns(ManagerQuery q) =>
      getList(ManagerModule.salesReturns, q, SalesReturnRecord.fromJson);

  Future<ManagerPage<SalesInvoiceRecord>> getSalesInvoices(ManagerQuery q) =>
      getList(ManagerModule.salesInvoices, q, SalesInvoiceRecord.fromJson);

  Future<ManagerPage<PaymentEntryRecord>> getPaymentEntries(ManagerQuery q) =>
      getList(ManagerModule.payments, q, PaymentEntryRecord.fromJson);

  Future<AttendanceDetail> getAttendanceDetail({
    required String employee,
    required String date,
  }) async {
    final data = await _get('get_attendance_detail', {
      'employee': employee,
      'date': date,
    });
    return AttendanceDetail.fromJson(data);
  }

  Future<TransactionDetail> getTransactionDetail({
    required String doctype,
    required String name,
  }) async {
    final data = await _get('get_transaction_detail', {
      'doctype': doctype,
      'name': name,
    });
    return TransactionDetail.fromJson(data);
  }
}
