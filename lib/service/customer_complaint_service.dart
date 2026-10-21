import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/customer_complaint_modal.dart';

class CustomerComplaintService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _listUrl =
      '${ApiConstants.complaintsBaseUrl}get_customer_complaints';
  final String _createUrl =
      '${ApiConstants.complaintsBaseUrl}create_customer_complaint';

  Future<String> _sid() async {
    final String? sid = await _secureStorage.read(key: 'sid');
    if (sid == null || sid.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }
    return sid;
  }

  /// Session cookie, needed to load private attachment files.
  Future<String?> readSid() => _secureStorage.read(key: 'sid');

  /// Full URL for a relative attachment path such as `/private/files/x.jpg`.
  static String attachmentUrl(String path) {
    if (path.startsWith('http')) return path;
    final host = ApiConstants.host.endsWith('/')
        ? ApiConstants.host.substring(0, ApiConstants.host.length - 1)
        : ApiConstants.host;
    return '$host${path.startsWith('/') ? '' : '/'}$path';
  }

  Future<CustomerComplaintList> getComplaints({
    String? status,
    String? customer,
    String? priority,
    String? fromDate,
    String? toDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _get({
      if (status != null && status.isNotEmpty) 'status': status,
      if (customer != null && customer.isNotEmpty) 'customer': customer,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      'limit': '$limit',
      'offset': '$offset',
    });
    if (data is! Map) throw Exception('Unexpected response from server.');
    return CustomerComplaintList.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CustomerComplaint> getComplaintDetail(String name) async {
    final data = await _get({'name': name});
    if (data is! Map) throw Exception('Unexpected response from server.');
    return CustomerComplaint.fromJson(Map<String, dynamic>.from(data));
  }

  /// Sends JSON when there is no file, multipart/form-data otherwise.
  Future<CustomerComplaint> createComplaint(
    CreateComplaintRequest request, {
    File? attachment,
  }) async {
    final sid = await _sid();
    final uri = Uri.parse(_createUrl);

    final http.Response response;
    try {
      if (attachment == null) {
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
          body: jsonEncode(request.toJson()),
        );
      } else {
        final multipart = http.MultipartRequest('POST', uri)
          ..headers['Cookie'] = 'sid=$sid'
          ..fields.addAll(request.toJson())
          ..files.add(
            await http.MultipartFile.fromPath('attachment', attachment.path),
          );
        response = await http.Response.fromStream(await multipart.send());
      }
    } catch (e) {
      print('[Complaint] POST $uri failed: $e');
      throw Exception('Network error. Please check your connection.');
    }

    print('[Complaint] POST $uri');
    print('[Complaint] Status: ${response.statusCode}');
    print('[Complaint] ${response.body}');

    final data = _unwrap(response);
    if (data is! Map) throw Exception('Unexpected response from server.');
    return CustomerComplaint.fromJson(Map<String, dynamic>.from(data));
  }

  Future<dynamic> _get(Map<String, String> query) async {
    final sid = await _sid();
    final uri = Uri.parse(_listUrl).replace(queryParameters: query);

    final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'},
      );
    } catch (e) {
      print('[Complaint] GET $uri failed: $e');
      throw Exception('Network error. Please check your connection.');
    }

    print('[Complaint] GET $uri');
    print('[Complaint] Status: ${response.statusCode}');
    final raw = response.body;
    for (var i = 0; i < raw.length; i += 800) {
      print('[Complaint] ${raw.substring(i, i + 800 > raw.length ? raw.length : i + 800)}');
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
      throw Exception(message);
    }
    throw Exception(_messageForStatus(response.statusCode));
  }

  String _messageForStatus(int code) {
    switch (code) {
      case 400:
        return 'Please check the details and try again.';
      case 401:
      case 403:
        return 'Session expired. Please login again.';
      case 404:
        return 'Complaint not found.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return 'Request failed. Code: $code';
    }
  }
}
