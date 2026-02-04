// item_stock_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/item_stock_modal.dart';

class ItemStockService {
  static const String baseUrl = "${ApiConstants.baseUrl}get_all_items_stock";

  Future<ItemStockModal> getAllStockItems() async {
    try {
      print("🌍 Calling API => $baseUrl");

      final response = await http.get(Uri.parse(baseUrl));

      print("📩 RESPONSE RECEIVED");
      print("Status Code => ${response.statusCode}");
      print("Headers => ${response.headers}");

      if (response.statusCode == 200) {
        print("✅ SUCCESS BODY => ${response.body}");
        return ItemStockModal.fromJson(json.decode(response.body));
      } else {
        print("❌ API ERROR");
        print("Reason => ${response.reasonPhrase}");
        print("Error Body => ${response.body}");
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 EXCEPTION OCCURRED");
      print("Error => $e");
      rethrow; // keeps throwing so controller can handle
    }
  }
}
