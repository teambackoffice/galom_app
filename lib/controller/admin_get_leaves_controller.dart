import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/admin_leaves_modal.dart';
import 'package:location_tracker_app/service/admin_get_leave_service.dart';

class GetAdminLeaveApplicationController extends ChangeNotifier {
  final GetAdminLeaveApplicationService _service =
      GetAdminLeaveApplicationService();

  bool isLoading = false;

  List<AdminLeaveApplicationModalClass> leaveApplications = [];

  Future<void> fetchLeaveApplications() async {
    isLoading = true;
    notifyListeners();

    final response = await _service.getLeaveApplications();

    if (response != null &&
        response.message.status.toLowerCase() == "success") {
      leaveApplications = response.message.applications;
    }

    isLoading = false;
    notifyListeners();
  }
}
