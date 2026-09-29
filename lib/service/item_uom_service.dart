import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/item_uom_modal.dart';

class ItemUomService {
  // This endpoint lives in the galom app, not sales_pilot, so only reuse the host.
  final String url =
      '${Uri.parse(ApiConstants.baseUrl).origin}/api/method/galom.galom.leave_api.get_item_uom_details';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<ItemUomDetails> fetchItemUom(String itemId) async {
    final sid = await _storage.read(key: "sid");
    if (sid == null) {
      throw Exception("User is not authenticated");
    }

    var headers = {'Cookie': 'sid=$sid'};
    final uri = Uri.parse(url).replace(queryParameters: {'item_id': itemId});

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final message = data['message'];
      if (message is Map<String, dynamic> && message['status'] == 'success') {
        return ItemUomDetails.fromJson(message);
      }
      throw Exception("Failed to fetch UOM details");
    } else {
      throw Exception("Failed to fetch UOM details");
    }
  }
}
