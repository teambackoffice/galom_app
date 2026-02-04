import 'package:flutter/widgets.dart';
import 'package:location_tracker_app/modal/items_list_modal.dart';
import 'package:location_tracker_app/service/item_list_service.dart';

class ItemListController extends ChangeNotifier {
  final ItemListService _service = ItemListService();
  ItemsListModal? itemlist;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchItemList() async {
    _isLoading = true;
    notifyListeners();
    try {
      itemlist = await _service.fetchItemList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
