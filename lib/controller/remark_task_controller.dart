import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/remarks_ask_service.dart';

class RemarkTaskController with ChangeNotifier {
  final RemarksTaskService _taskService = RemarksTaskService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Update task status
  Future<void> updateTask(String taskName, String remarks) async {
    _setLoading(true);

    var response = await _taskService.addRemarks(
      taskName: taskName,
      remarks: remarks,
    );

    _setLoading(false);

    if (response != null) {
    } else {}
  }

  /// Add remarks to a task
  Future<void> addRemarks(String taskName, String remarks) async {
    _setLoading(true);

    var response = await _taskService.addRemarks(
      taskName: taskName,
      remarks: remarks,
    );

    _setLoading(false);

    if (response != null) {
    } else {}
  }

  /// Helper to update loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
