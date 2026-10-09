import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_stock_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';

/// Stock inventory for the Manager section, from
/// `sales_pilot.Api.auth.get_all_items_stock` on the stock server
/// ([ApiConstants.stockUrl]).
///
/// The login session belongs to the main ERP host, so it is not sent here
/// (same as the existing salesperson stock screen).
class ManagerStockService {
  ManagerStockService({http.Client? client, String? url})
    : _client = client,
      _url = url ?? ApiConstants.stockUrl;

  final http.Client? _client;
  final String _url;

  Future<List<StockItem>> getStock() async {
    const headers = {'Content-Type': 'application/json'};
    http.Response res;
    try {
      final uri = Uri.parse(_url);
      final c = _client;
      res =
          await (c != null
                  ? c.get(uri, headers: headers)
                  : http.get(uri, headers: headers))
              .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ManagerApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      debugPrint('Stock API network error: $e');
      throw const ManagerApiException(
        'Unable to reach the server. Check your internet connection.',
      );
    }
    return parse(res.statusCode, res.body);
  }

  @visibleForTesting
  static List<StockItem> parse(int statusCode, String rawBody) {
    dynamic body;
    try {
      body = rawBody.isEmpty ? null : jsonDecode(rawBody);
    } on FormatException {
      body = null;
    }
    // Not our login session, so never "session expired" here.
    if (statusCode == 401 || statusCode == 403) {
      throw ManagerApiException(
        'The stock server refused the request ($statusCode).',
        statusCode: statusCode,
      );
    }
    final message = body is Map ? asMap(body['message']) : <String, dynamic>{};
    if (statusCode != 200 ||
        asString(message['status']).toLowerCase() == 'error') {
      throw ManagerApiException(
        asStringOrNull(message['message']) ??
            (statusCode >= 500
                ? 'Server error. Please try again.'
                : 'Could not load stock.'),
        statusCode: statusCode,
      );
    }
    return StockItem.fromRows(asMapList(message['data']));
  }
}
