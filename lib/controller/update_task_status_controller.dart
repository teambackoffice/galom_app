import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/update_task_status.dart';

class UpdateTaskStatusController with ChangeNotifier {
  final UpdateTaskStatus _taskService = UpdateTaskStatus();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Updated method to support completion date
  Future<bool> updateTask({
    required String taskName,
    required String status,
    DateTime? completionDate, // Added optional completion date parameter
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await _taskService.updateTaskStatus(
        taskName: taskName,
        status: status,
        completionDate: completionDate, // Pass the completion date
      );

      _isLoading = false;
      notifyListeners();

      if (response != null) {
        return true; // Return success
      } else {
        return false; // Return failure
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false; // Return failure
    }
  }

  /// New method with named parameters for clarity
}
