import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/admin_get_leaves_controller.dart';
import 'package:location_tracker_app/controller/approve_reject_leave_controller.dart';
import 'package:location_tracker_app/service/login_service.dart';
import 'package:location_tracker_app/view/mainscreen/leave/gm_leave/leave_list.dart';
import 'package:provider/provider.dart';

class LeaveDetailScreen extends StatefulWidget {
  final LeaveRequest leave;
  const LeaveDetailScreen({super.key, required this.leave});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late LeaveRequest leave;
  String? _userRoleProfile;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    leave = widget.leave;
    _loadUserRoleProfile();
  }

  Future<void> _loadUserRoleProfile() async {
    try {
      final profile = await LoginService().getRoleProfile();
      if (mounted) {
        setState(() {
          _userRoleProfile = profile;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  Future<void> _setStatus(LeaveStatus status) async {
    final isApproved = status == LeaveStatus.approved;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.greenSoft : AppColors.redSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isApproved ? AppColors.green : AppColors.red,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isApproved ? 'Approve leave?' : 'Reject leave?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isApproved
                    ? 'You are about to approve the leave request from ${leave.name}. This action will notify the employee.'
                    : 'You are about to reject the leave request from ${leave.name}. This action will notify the employee.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.inkMuted,
                  fontFamily: 'Roboto',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkMuted,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isApproved
                            ? AppColors.green
                            : AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        isApproved ? 'Yes, approve' : 'Yes, reject',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          margin: const EdgeInsets.all(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.indigo),
                SizedBox(height: 16),
                Text(
                  'Updating status...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final controller = Provider.of<LeaveApprovalRejectController>(
      context,
      listen: false,
    );
    Map<String, dynamic> result;
    if (isApproved) {
      result = await controller.approveLeave(leave.id);
    } else {
      result = await controller.rejectLeave(leave.id);
    }

    // Dismiss loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    final isSuccess = result['status'] != 'error';

    if (!isSuccess) {
      if (mounted) {
        final errorMsg = result['message'] ?? 'Failed to update leave status.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    setState(() {
      leave.status = status;
      leave.rawStatus = _statusToApiString(status);
    });

    if (mounted) {
      final successMsg = isApproved
          ? 'Leave request approved for ${leave.name}'
          : 'Leave request rejected for ${leave.name}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: isApproved ? AppColors.green : AppColors.red,
        ),
      );
    }

    if (mounted && Navigator.of(context).canPop()) {
      Provider.of<GetAdminLeaveApplicationController>(
        context,
        listen: false,
      ).fetchLeaveApplications();
      Navigator.of(context).pop();
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.inkMuted),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.inkMuted,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontFamily: 'Roboto',
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(leave.status);
    final colors = avatarColors(leave.id);

    final rawStatusLower = leave.rawStatus.trim().toLowerCase();
    final isPendingForManager =
        rawStatusLower.contains('manager') ||
        rawStatusLower.contains('manger') ||
        rawStatusLower.contains('waiting for manager');
    final isPendingForAdmin =
        rawStatusLower.contains('admin') ||
        rawStatusLower == 'open' ||
        (rawStatusLower.contains('pending') && !isPendingForManager);

    final userRoleLower = (_userRoleProfile ?? '').trim().toLowerCase();
    final isUserAdmin = userRoleLower == 'admin';
    final isUserManager = userRoleLower == 'manager';

    final showButtons =
        !_isLoadingRole &&
        ((isPendingForAdmin && (isUserAdmin || isUserManager)) ||
            (isPendingForManager && isUserManager));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Provider.of<GetAdminLeaveApplicationController>(
                context,
                listen: false,
              ).fetchLeaveApplications();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6E)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF764BA2).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_ind_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Request details',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon, size: 14, color: style.fg),
                  const SizedBox(width: 5),
                  Text(
                    leave.rawStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: style.fg,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors[0],
                  child: Text(
                    leave.initials,
                    style: TextStyle(
                      color: colors[1],
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        leave.role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            Row(
              children: [
                _infoTile(Icons.beach_access_rounded, 'Leave type', leave.type),
                const SizedBox(width: 10),
                _infoTile(
                  Icons.event_rounded,
                  'Duration',
                  '${leave.days} day${leave.days > 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoTile(
                  Icons.donut_small_rounded,
                  'Balance',
                  '${leave.balance} days left',
                ),
                const SizedBox(width: 10),
                _infoTile(Icons.history_rounded, 'Applied on', leave.applied),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _dateRow('From', leave.from),
                  const Divider(height: 1, color: AppColors.line),
                  _dateRow('To', leave.to),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.inkMuted,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                leave.reason,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.ink,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: showButtons
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(
                          color: AppColors.red,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _setStatus(LeaveStatus.rejected),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _setStatus(LeaveStatus.approved),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Approve',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _StatusStyle {
  final Color fg;
  final Color bg;
  final String label;
  final IconData icon;
  const _StatusStyle(this.fg, this.bg, this.label, this.icon);
}

_StatusStyle statusStyle(LeaveStatus s) {
  switch (s) {
    case LeaveStatus.approved:
      return const _StatusStyle(
        AppColors.green,
        AppColors.greenSoft,
        'Approved',
        Icons.check_circle_rounded,
      );
    case LeaveStatus.rejected:
      return const _StatusStyle(
        AppColors.red,
        AppColors.redSoft,
        'Rejected',
        Icons.cancel_rounded,
      );
    case LeaveStatus.pending:
      return const _StatusStyle(
        AppColors.amber,
        AppColors.amberSoft,
        'Pending',
        Icons.schedule_rounded,
      );
  }
}

String _statusToApiString(LeaveStatus s) {
  switch (s) {
    case LeaveStatus.approved:
      return 'Approved';
    case LeaveStatus.rejected:
      return 'Rejected';
    case LeaveStatus.pending:
      return 'Open';
  }
}
