import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/remark_task_controller.dart';
import 'package:location_tracker_app/controller/task_controller.dart';
import 'package:location_tracker_app/controller/update_task_status_controller.dart';
import 'package:location_tracker_app/modal/task_modal.dart';
import 'package:provider/provider.dart';

enum TaskStatus { Open, InProgress, Completed, Overdue }

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.Open:
        return 'Open';
      case TaskStatus.InProgress:
        return 'In Progress';
      case TaskStatus.Completed:
        return 'Completed';
      case TaskStatus.Overdue:
        return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.Open:
        return Colors.blue;
      case TaskStatus.InProgress:
        return Colors.orange;
      case TaskStatus.Completed:
        return const Color(0xFF4CAF50);
      case TaskStatus.Overdue:
        return const Color(0xFFB71C1C);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.Open:
        return Icons.radio_button_unchecked;
      case TaskStatus.InProgress:
        return Icons.play_circle_outline;
      case TaskStatus.Completed:
        return Icons.check_circle;
      case TaskStatus.Overdue:
        return Icons.warning;
    }
  }
}

class TaskDetailPage extends StatefulWidget {
  final Datum task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Datum currentTask;
  late TaskStatus currentStatus;

  // Controller instances
  final UpdateTaskStatusController _statusController =
      UpdateTaskStatusController();
  final RemarkTaskController _remarksController = RemarkTaskController();

  @override
  void initState() {
    super.initState();
    currentTask = widget.task;
    currentStatus = _getTaskStatus(currentTask.status ?? '');
  }

  // Helper method to convert API status to TaskStatus enum
  TaskStatus _getTaskStatus(String? apiStatusRaw) {
    final apiStatus = (apiStatusRaw ?? '').toLowerCase().trim();
    switch (apiStatus) {
      case 'open':
        return TaskStatus.Open;
      case 'completed':
        return TaskStatus.Completed;
      case 'overdue':
        return TaskStatus.Overdue;
      case 'in progress':
      case 'working':
        return TaskStatus.InProgress;
      default:
        return TaskStatus.InProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: const Color(0xFF764BA2),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeaderCard(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildTimelineCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            if ((currentTask.customRemarks?.toString() ?? '').isNotEmpty)
              const SizedBox(height: 16),
            if ((currentTask.customRemarks?.toString() ?? '').isNotEmpty)
              _buildRemarksCard(),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStatusDialog,
        backgroundColor: const Color(0xFF764BA2),
        label: const Text(
          'Update Status',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTaskHeaderCard() {
    final assigned = currentTask.customAssignedTo ?? '';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTask.subject ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Task ID: ${currentTask.name ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (assigned.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Assigned to: $assigned',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _buildDetailCard('Customer Information', Icons.person, [
      _buildDetailRow('Customer Name', currentTask.customCustomer ?? ""),
    ]);
  }

  Widget _buildTimelineCard() {
    return _buildDetailCard('Task Timeline', Icons.schedule, [
      _buildDetailRow('Start Date', _formatDateSafe(currentTask.expStartDate)),
      _buildDetailRow('End Date', _formatDateSafe(currentTask.expEndDate)),
      _buildDetailRow('Duration', _calculateDurationSafe()),
    ]);
  }

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF764BA2)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF764BA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusText = currentTask.status ?? currentStatus.displayName;
    final isCancelled = statusText.toLowerCase() == 'cancelled';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.flag, color: Color(0xFF764BA2)),
                SizedBox(width: 8),
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF764BA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.red
                    : currentStatus.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentStatus.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCancelled ? Colors.red : currentStatus.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCancelled ? Icons.cancel : currentStatus.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCancelled
                              ? Colors.white
                              : currentStatus.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final desc = currentTask.description?.trim() ?? '';
    final hasDesc = desc.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description, color: Color(0xFF764BA2)),
                SizedBox(width: 8),
                Text(
                  'Task Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF764BA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                hasDesc ? desc : 'No description provided',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: hasDesc ? Colors.black87 : Colors.grey[500],
                  fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    final remarks = currentTask.customRemarks?.toString() ?? '';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.comment, color: Color(0xFF764BA2)),
                SizedBox(width: 8),
                Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF764BA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                remarks,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateSafe(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _calculateDurationSafe() {
    final start = currentTask.expStartDate;
    final end = currentTask.expEndDate;
    final difference = end.difference(start);
    final days = difference.inDays + 1;

    if (days <= 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 30) {
      final weeks = (days / 7).floor();
      final remainingDays = days % 7;
      String result = '$weeks week${weeks > 1 ? 's' : ''}';
      if (remainingDays > 0) {
        result += ' $remainingDays day${remainingDays > 1 ? 's' : ''}';
      }
      return result;
    } else {
      final months = (days / 30).floor();
      final remainingDays = days % 30;
      String result = '$months month${months > 1 ? 's' : ''}';
      if (remainingDays > 0) {
        result += ' $remainingDays day${remainingDays > 1 ? 's' : ''}';
      }
      return result;
    }
  }

  void _showStatusDialog() {
    final TextEditingController remarksController = TextEditingController();
    TaskStatus selectedStatus = currentStatus;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  SizedBox(width: 8),
                  Text('Update Task Status'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select new status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TaskStatus.values.map((status) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: selectedStatus == status
                              ? status.color.withOpacity(0.1)
                              : null,
                        ),
                        child: RadioListTile<TaskStatus>(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          value: status,
                          groupValue: selectedStatus,
                          onChanged: (TaskStatus? value) {
                            setStateDialog(() {
                              selectedStatus = value ?? selectedStatus;
                            });
                          },
                          title: Row(
                            children: [
                              Icon(status.icon, color: status.color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                status.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: selectedStatus == status
                                      ? status.color
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          activeColor: status.color,
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: "Add remarks (optional)",
                        hintText: "Enter any additional comments...",
                        prefixIcon: const Icon(Icons.comment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF764BA2),
                          ),
                        ),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF764BA2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setStateDialog(() {
                            isLoading = true;
                          });

                          final remarks = remarksController.text.trim().isEmpty
                              ? null
                              : remarksController.text.trim();

                          await _updateTaskWithBothAPIs(
                            selectedStatus,
                            remarks: remarks,
                          );

                          // Refresh tasks and close dialog
                          Provider.of<EmployeeTaskController>(
                            context,
                            listen: false,
                          ).fetchTasks();
                          Navigator.of(context).pop();
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Update Status"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Updated method to handle both APIs
  Future<void> _updateTaskWithBothAPIs(
    TaskStatus newStatus, {
    String? remarks,
  }) async {
    try {
      // Determine what needs to be updated
      bool statusChanged = currentStatus != newStatus;
      bool hasRemarks = remarks != null && remarks.isNotEmpty;

      // Get task name from currentTask
      String taskName = getTaskName();

      List<Future> apiCalls = [];

      // Call status update API if status changed
      if (statusChanged) {
        // Prepare completion date if status is completed
        DateTime? completionDate;
        if (newStatus == TaskStatus.Completed) {
          completionDate = DateTime.now();
        }

        apiCalls.add(
          _statusController.updateTask(
            taskName: taskName,
            status: newStatus == TaskStatus.InProgress
                ? "Working"
                : newStatus.displayName,
            completionDate: completionDate,
          ),
        );
      }

      // Call remarks API if remarks provided
      if (hasRemarks) {
        apiCalls.add(_remarksController.addRemarks(taskName, remarks));
      }

      // Execute all API calls concurrently
      if (apiCalls.isNotEmpty) {
        await Future.wait(apiCalls);

        // Update local state after successful API calls
        if (statusChanged) {
          setState(() {
            currentStatus = newStatus;
            // Update display string on the task
            switch (newStatus) {
              case TaskStatus.Open:
                currentTask.status = 'Open';
                break;
              case TaskStatus.Completed:
                currentTask.status = 'Completed';
                break;
              case TaskStatus.Overdue:
                currentTask.status = 'Overdue';
                break;
              case TaskStatus.InProgress:
                currentTask.status = 'In Progress';
                break;
            }
          });
        }

        if (hasRemarks) {
          setState(() {
            currentTask.customRemarks = remarks;
          });
        }

        // Show success message
        _showSuccessMessage(statusChanged, hasRemarks);
      }
    } catch (e) {
      // Handle errors
      _showErrorMessage(e.toString());
    }
  }

  /// Helper method to get task name
  String getTaskName() {
    return widget.task.name ?? '';
  }

  /// Show success message
  void _showSuccessMessage(bool statusUpdated, bool remarksAdded) {
    String message = "";
    if (statusUpdated && remarksAdded) {
      message = "Task status and remarks updated successfully!";
    } else if (statusUpdated) {
      message = "Task status updated successfully!";
    } else if (remarksAdded) {
      message = "Remarks added successfully!";
    }

    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $error"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
