// controllers/leave_application_controller.dart

import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/leave_applicatrion_modal.dart';
import 'package:location_tracker_app/service/leave_application_service.dart';

class GetLeaveApplicationController extends ChangeNotifier {
  final GetLeaveApplicationService _service = GetLeaveApplicationService();

  LeaveApplicationModalClass? leaveData;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchLeaveApplications() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final response = await _service.getLeaveApplications();

      if (response != null) {
        leaveData = response;
      } else {
        errorMessage = 'Failed to load leave applications';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
