// item_stock_controller.dart
import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/item_stock_service.dart';

import '../modal/item_stock_modal.dart';

class ItemStockController extends ChangeNotifier {
  final ItemStockService _service = ItemStockService();

  bool isLoading = false;
  List<Datum> items = [];
  String? errorMessage;

  Future<void> fetchItems() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final res = await _service.getAllStockItems();

      items = res.message.data;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
