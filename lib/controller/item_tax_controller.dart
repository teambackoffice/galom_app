import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/item_tax_modal.dart';
import 'package:location_tracker_app/service/item_tax_service.dart';

class ItemTaxController with ChangeNotifier {
  final ItemTaxService _service = ItemTaxService();

  List<ItemTax> _itemTaxes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ItemTax> get itemTaxes => _itemTaxes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getItemTaxes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itemTaxes = await _service.fetchItemTax();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
