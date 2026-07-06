import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/leave_type_modal.dart';
import 'package:location_tracker_app/service/leave _type_service.dart';

class LeaveTypesController extends ChangeNotifier {
  final LeaveTypesService _service = LeaveTypesService();

  List<String> leaveTypes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadLeaveTypes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final LeaveTypesResponse? response = await _service.getLeaveTypes();

    if (response != null && response.status == 'success') {
      leaveTypes = response.leaveTypes;
    } else {
      errorMessage = 'Failed to load leave types';
    }

    isLoading = false;
    notifyListeners();
  }
}
