import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/task_controller.dart';
import 'package:location_tracker_app/modal/task_modal.dart';
import 'package:location_tracker_app/view/mainscreen/tasks/task_details.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

enum TaskStatus { inProgress, completed, cancelled, overdue }

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Color(0xFF4CAF50);
      case TaskStatus.overdue:
        return Color(0xFFB71C1C);
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.overdue:
        return Icons.warning;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class EmployeeTasks extends StatefulWidget {
  const EmployeeTasks({super.key});

  @override
  State<EmployeeTasks> createState() => _EmployeeTasksState();
}

class _EmployeeTasksState extends State<EmployeeTasks> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeTaskController>(context, listen: false).fetchTasks();
    });
  }

  // Helper method to convert API status to TaskStatus enum
  TaskStatus _getTaskStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'overdue':
        return TaskStatus.overdue;
      case 'in progress':
      case 'working':
      default:
        return TaskStatus.inProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<EmployeeTaskController>(
          builder: (context, controller, child) {
            final tasks = controller.tasks; // Now directly List<Datum>
            final isLoading = controller.isLoading;
            final errorMessage = controller.errorMessage;

            if (isLoading) {
              return _buildShimmerLoading();
            }

            if (errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[300]),
                    SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchTasks(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            List<Datum> allTasks = [];
            for (var taskModal in tasks) {
              allTasks.addAll(taskModal.message.data);
            }

            return Column(
              children: [
                _buildHeader(allTasks.length),
                Expanded(
                  child: allTasks.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => controller.fetchTasks(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: allTasks.length,
                            itemBuilder: (context, index) {
                              final task = allTasks[index];
                              return _buildTaskCard(task, index);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int taskCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Gradient Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF764BA2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
          ),

          const SizedBox(width: 16),

          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employee Tasks',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new assignments',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Datum task, int index) {
    final status = _getTaskStatus(task.status);
    final description = task.description ?? '';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task header with subject and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: status.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 16, color: status.color),
                        const SizedBox(width: 4),
                        Text(
                          task.status == "Working"
                              ? "In Progress"
                              : task.status,
                          style: TextStyle(
                            color: status.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Customer information
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Customer: ${task.customCustomer}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Start date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${_formatDate(task.expStartDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // End date
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'End: ${_formatDate(task.expEndDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Description - FIXED: Now handles null values safely
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerTaskCard(),
    );
  }

  Widget _buildShimmerTaskCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Status
              Row(
                children: [
                  Expanded(
                    child: _shimmerBox(height: 18, width: double.infinity),
                  ),
                  const SizedBox(width: 12),
                  _shimmerBox(height: 20, width: 80, radius: 20),
                ],
              ),

              const SizedBox(height: 16),

              // Customer
              _shimmerRow(),

              const SizedBox(height: 8),

              // Start date
              _shimmerRow(),

              const SizedBox(height: 8),

              // End date
              _shimmerRow(),

              const SizedBox(height: 12),

              // Description
              _shimmerBox(height: 14, width: double.infinity),
              const SizedBox(height: 6),
              _shimmerBox(height: 14, width: 200),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    required double width,
    double radius = 6,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerRow() {
    return Row(
      children: [
        _shimmerBox(height: 16, width: 16, radius: 4),
        const SizedBox(width: 8),
        _shimmerBox(height: 14, width: 160),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _navigateToTaskDetail(Datum task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
    );
  }
}
