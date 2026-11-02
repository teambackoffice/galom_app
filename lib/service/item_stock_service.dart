// item_stock_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/item_stock_modal.dart';

class ItemStockService {
  static const String baseUrl =
      "https://metta.tbocloud.in/api/method/sales_pilot.Api.auth.get_all_items_stock";

  Future<ItemStockModal> getAllStockItems() async {
    try {

      final response = await http.get(Uri.parse(baseUrl));


      if (response.statusCode == 200) {
        return ItemStockModal.fromJson(json.decode(response.body));
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow; // keeps throwing so controller can handle
    }
  }
}
