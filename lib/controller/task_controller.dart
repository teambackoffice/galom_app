import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/task_modal.dart';
import 'package:location_tracker_app/service/task_service.dart';

class EmployeeTaskController extends ChangeNotifier {
  final EmployeeTaskService _taskService = EmployeeTaskService();

  List<EmployeeTaskModal> tasks = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchTasks() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      tasks = await _taskService.getTaskDetails();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
