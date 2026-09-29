import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/item_uom_modal.dart';
import 'package:location_tracker_app/service/item_uom_service.dart';

class ItemUomController with ChangeNotifier {
  final ItemUomService _service = ItemUomService();

  // Cached per item so reopening the same item doesn't refetch
  final Map<String, ItemUomDetails> _cache = {};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ItemUomDetails? uomFor(String itemId) => _cache[itemId];

  Future<ItemUomDetails?> getItemUom(String itemId) async {
    if (_cache.containsKey(itemId)) return _cache[itemId];

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cache[itemId] = await _service.fetchItemUom(itemId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _cache[itemId];
  }
}
