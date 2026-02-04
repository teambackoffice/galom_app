import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:location_tracker_app/service/customer_list_service.dart';

class GetCustomerListController extends ChangeNotifier {
  final CustomerListService _service = CustomerListService();
  CustomerListModal? customerlist;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCustomerList() async {
    _isLoading = true;
    notifyListeners();
    try {
      customerlist = await _service.fetchCustomerList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
