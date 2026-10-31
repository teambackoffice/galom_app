import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';

class ExpenseClaimService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _base = ApiConstants.baseUrl;

  Future<String> _sid() async {
    final String? sid = await _secureStorage.read(key: 'sid');
    if (sid == null || sid.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }
    return sid;
  }

  /// Session cookie, needed to load private receipt files.
  Future<String?> readSid() => _secureStorage.read(key: 'sid');

  Future<List<ExpenseClaim>> getMyClaims({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _get('get_my_expense_claims', {
      if (status != null && status.isNotEmpty) 'status': status,
      'limit': '$limit',
      'offset': '$offset',
    });
    final raw = data is Map ? data['claims'] : null;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ExpenseClaim.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ExpenseClaimDetail> getClaimDetail(String name) async {
    final data = await _get('get_expense_claim_detail', {'name': name});
    if (data is! Map) throw Exception('Unexpected response from server.');
    return ExpenseClaimDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ExpenseSummary> getSummary() async {
    final data = await _get('get_my_expense_summary', const {});
    if (data is! Map) throw Exception('Unexpected response from server.');
    return ExpenseSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<String>> getExpenseTypes() async {
    final data = await _get('get_expense_claim_types', const {});
    final raw = data is Map ? data['types'] : null;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => '${e['name'] ?? ''}')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// Sends JSON when there are no receipts, multipart/form-data otherwise.
  Future<CreatedExpenseClaim> createClaim({
    required List<NewExpenseLine> lines,
    String? postingDate,
    String? remark,
    List<File> receipts = const [],
  }) async {
    final sid = await _sid();
    final uri = Uri.parse('${_base}create_expense_claim');
    final lineJson = lines.map((l) => l.toJson()).toList();

    final http.Response response;
    try {
      if (receipts.isEmpty) {
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
          body: jsonEncode({
            if (postingDate != null) 'posting_date': postingDate,
            if (remark != null) 'remark': remark,
            'expenses': lineJson,
          }),
        );
      } else {
        final req = http.MultipartRequest('POST', uri)
          ..headers['Cookie'] = 'sid=$sid'
          ..fields['expenses'] = jsonEncode(lineJson);
        if (postingDate != null) req.fields['posting_date'] = postingDate;
        if (remark != null) req.fields['remark'] = remark;
        for (final file in receipts) {
          req.files.add(await http.MultipartFile.fromPath('receipts', file.path));
        }
        response = await http.Response.fromStream(await req.send());
      }
    } catch (e) {
      print('[Expense] POST $uri failed: $e');
      throw Exception('Network error. Please check your connection.');
    }

    print('[Expense] POST $uri');
    print('[Expense] Status: ${response.statusCode}');
    print('[Expense] ${response.body}');

    final data = _unwrap(response);
    if (data is! Map) throw Exception('Unexpected response from server.');
    return CreatedExpenseClaim.fromJson(Map<String, dynamic>.from(data));
  }

  Future<dynamic> _get(String method, Map<String, String> query) async {
    final sid = await _sid();
    final uri = Uri.parse('$_base$method')
        .replace(queryParameters: query.isEmpty ? null : query);

    final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );
    } catch (e) {
      print('[Expense] GET $uri failed: $e');
      throw Exception('Network error. Please check your connection.');
    }

    print('[Expense] GET $uri');
    print('[Expense] Status: ${response.statusCode}');
    final raw = response.body;
    for (var i = 0; i < raw.length; i += 800) {
      print('[Expense] ${raw.substring(i, i + 800 > raw.length ? raw.length : i + 800)}');
    }

    return _unwrap(response);
  }

  /// Returns `data` only when `statusCode == 200 && success == true`.
  dynamic _unwrap(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode == 200 && body is Map && body['success'] == true) {
      return body['data'];
    }

    final message = body is Map ? body['message'] : null;
    if (message is String &&
        message.trim().isNotEmpty &&
        response.statusCode != 401) {
      throw Exception(_plainText(message));
    }
    throw Exception(_messageForStatus(response.statusCode));
  }

  /// Frappe messages can contain HTML such as `<strong>` or `<a href>`.
  String _plainText(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _messageForStatus(int code) {
    switch (code) {
      case 400:
        return 'Please check the details and try again.';
      case 401:
      case 403:
        return 'Session expired. Please login again.';
      case 404:
        return 'Your account is not linked to an Employee.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return 'Request failed. Code: $code';
    }
  }
}
