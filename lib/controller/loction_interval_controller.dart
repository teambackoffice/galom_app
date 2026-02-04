import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/modal/location_interval_modal.dart';
import 'package:location_tracker_app/service/location_interval_service.dart';

class LocationIntervalController extends ChangeNotifier {
  final LocationIntervalService _service = LocationIntervalService();

  LocationIntervalModal? locationInterval;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchLocationUpdateInterval() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final data = await _service.getLocationUpdateInterval();

    if (data != null) {
      locationInterval = data;
    } else {
      errorMessage = "Failed to fetch location update interval.";
    }

    isLoading = false;
    notifyListeners();
  }
}
