import 'package:flutter/foundation.dart';
import 'package:location_tracker_app/service/customer_log_visit_service.dart';

class LogCustomerVisitController extends ChangeNotifier {
  final LogCustomerVisitService _service = LogCustomerVisitService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? responseData;

  Future<void> logCustomerVisit({
    required String date,
    required String time,
    required double longitude,
    required double latitude,
    required String customerName,
    required String description,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.logCustomerVisit(
        date: date,
        time: time,
        longitude: longitude,
        latitude: latitude,
        customerName: customerName,
        description: description,
      );

      responseData = result;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
