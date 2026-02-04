// controllers/special_offer_controller.dart
import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/special_offer/get_special_offer.dart';

class GetSpecialOfferController extends ChangeNotifier {
  final GetSpecialOfferService _service = GetSpecialOfferService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _settings;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get settings => _settings;

  /// Fetch Chundakadan settings (GET API)
  Future<void> fetchChundakadanSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getChundakadanSettings();
      _settings = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
