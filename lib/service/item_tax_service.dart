import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/item_tax_modal.dart';

class ItemTaxService {
  final String url = '${ApiConstants.baseUrl}get_item_tax';

  // Secure storage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<ItemTax>> fetchItemTax() async {
    try {
      // 🔹 Get sid from secure storage
      final sid = await _storage.read(key: "sid");
      if (sid == null) {
        throw Exception("User is not authenticated");
      }

      var headers = {'Cookie': 'full_name=najath; sid=$sid; '};

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['message'] != null) {
          List<ItemTax> taxes = (data['message'] as List)
              .map((e) => ItemTax.fromJson(e))
              .toList();
          return taxes;
        } else {
          return [];
        }
      } else {
        throw Exception("Failed to fetch item tax");
      }
    } catch (e, stacktrace) {
      rethrow;
    }
  }
}
