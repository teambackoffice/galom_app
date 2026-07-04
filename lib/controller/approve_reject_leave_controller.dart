import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/approve_reject_leave_service.dart';

class LeaveApprovalRejectController extends ChangeNotifier {
  final LeaveApprovalRejectService _service = LeaveApprovalRejectService();

  bool isLoading = false;

  Future<Map<String, dynamic>> approveLeave(String docName) async {
    isLoading = true;
    notifyListeners();

    final result = await _service.approveLeave(docName: docName);

    isLoading = false;
    notifyListeners();

    return result;
  }

  Future<Map<String, dynamic>> rejectLeave(String docName) async {
    isLoading = true;
    notifyListeners();

    final result = await _service.rejectLeave(docName: docName);

    isLoading = false;
    notifyListeners();

    return result;
  }
}
