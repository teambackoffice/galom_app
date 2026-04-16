// controllers/create_leave_application_controller.dart

import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/create_leave_service.dart';

class CreateLeaveApplicationController extends ChangeNotifier {
  final CreateLeaveApplicationService _service =
      CreateLeaveApplicationService();

  bool isLoading = false;
  bool isSuccess = false;
  String? errorMessage;
  Map<String, dynamic>? responseData;

  Future<void> submitLeaveApplication({
    required String employee,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String description,
    required int halfDay,
    String? halfDayDate,
  }) async {
    try {
      isLoading = true;
      isSuccess = false;
      errorMessage = null;
      notifyListeners();

      final response = await _service.createLeaveApplication(
        employee: employee,
        leaveType: leaveType,
        fromDate: fromDate,
        toDate: toDate,
        description: description,
        halfDay: halfDay,
        halfDayDate: halfDayDate,
      );

      if (response != null) {
        responseData = response;
        isSuccess = true;
      } else {
        errorMessage = 'Failed to submit leave application';
      }
    } catch (e) {
      errorMessage = e.toString();
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
