// leave_list_page.dart — drop-in replacement for LeaveListPage + LeaveCard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location_tracker_app/controller/create_leave_controller.dart';
import 'package:location_tracker_app/controller/leave_application_controller.dart';
import 'package:location_tracker_app/modal/leave_applicatrion_modal.dart';
import 'leave_application.dart'; // LeaveRequest, LeaveStatus, LeaveApplySheet

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  String _filter = 'All';
  final _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  static const _months = [
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

  String _monthKey(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetLeaveApplicationController>().fetchLeaveApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Consumer<GetLeaveApplicationController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                _TopBar(
                  filter: _filter,
                  filters: _filters,
                  onFilter: (f) => setState(() => _filter = f),
                ),
                Expanded(child: _buildBody(controller)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(GetLeaveApplicationController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A1A1A),
          strokeWidth: 2,
        ),
      );
    }

    if (controller.errorMessage != null) {
      return _buildError(controller);
    }

    final apps = controller.leaveData?.message?.applications;
    if (apps == null || apps.isEmpty) return _buildEmpty();

    // Filter at the Application level so we still have fromDate for grouping
    final filtered = _filter == 'All'
        ? apps
        : apps
              .where((a) => a.status.toLowerCase() == _filter.toLowerCase())
              .toList();

    if (filtered.isEmpty) return _buildEmpty();

    // Group by month using Application.fromDate
    final groups = <String, List<Application>>{};
    for (final a in filtered) {
      final key = _monthKey(a.fromDate);
      (groups[key] ??= []).add(a);
    }

    // Flatten into mixed list: String (month header) | Application (card)
    final items = <Object>[];
    groups.forEach((month, list) {
      items.add(month);
      items.addAll(list);
    });

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () => controller.fetchLeaveApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item is String) return _MonthLabel(label: item);
          final app = item as Application;
          return LeaveCard(leave: LeaveRequest.fromApplication(app));
        },
      ),
    );
  }

  Widget _buildError(GetLeaveApplicationController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFD3D1C7),
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: controller.fetchLeaveApplications,
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFD3D1C7)),
          SizedBox(height: 12),
          Text(
            'No leave applications',
            style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () => _showApplySheet(context),
          backgroundColor: const Color(0xFF1A3A6E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Apply for leave',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void _showApplySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => CreateLeaveApplicationController(),
        child: const LeaveApplySheet(),
      ),
    );
  }
}

// ── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String filter;
  final List<String> filters;
  final ValueChanged<String> onFilter;

  const _TopBar({
    required this.filter,
    required this.filters,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: Color(0xFF888780),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'My leaves',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filters.length,
              itemBuilder: (_, i) => _FilterTab(
                label: filters[i],
                active: filter == filters[i],
                onTap: () => onFilter(filters[i]),
              ),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF3B6D11) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? const Color(0xFF3B6D11) : const Color(0xFF888780),
          ),
        ),
      ),
    );
  }
}

// ── Month label ──────────────────────────────────────────────────────────────

class _MonthLabel extends StatelessWidget {
  final String label;
  const _MonthLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888780),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Leave card ───────────────────────────────────────────────────────────────

class LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  const LeaveCard({super.key, required this.leave});

  String get _daysLabel {
    final d = leave.days;
    final n = d % 1 == 0 ? d.toInt().toString() : '0.5';
    return '$n ${d == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeaveDetailPage(leave: leave)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status accent bar
                Container(width: 3.5, color: leave.status.barColor),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type + chip
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leave.type,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusChip(status: leave.status),
                                ],
                              ),
                              const SizedBox(height: 7),
                              // Date + days badge
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      leave.dateRange,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _DaysBadge(label: _daysLabel),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LeaveStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: status.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.chipText,
        ),
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  final String label;
  const _DaysBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF888780),
        ),
      ),
    );
  }
}
