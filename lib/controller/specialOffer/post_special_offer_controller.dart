// controllers/special_offer_controller.dart
import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/special_offer/post_special_offer_service.dart';

class SpecialOfferController extends ChangeNotifier {
  final SpecialOfferService _service = SpecialOfferService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _responseData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get responseData => _responseData;

  Future<void> updateSpecialOfferSettings(bool enableStockValidation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.updateSpecialOfferSettings(
        enableStockValidation: enableStockValidation,
      );
      _responseData = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
