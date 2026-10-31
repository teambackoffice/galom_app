import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/view/manager/attendance/attendance_detail.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/module_list_view.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Attendance list (body of the Team → Attendance tab).
class AttendanceListView extends StatelessWidget {
  const AttendanceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<AttendanceRecord>(
      controller: context.read<ManagerListController<AttendanceRecord>>(),
      searchHint: 'Search employee',
      statuses: const [],
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: 'No attendance records',
      summaryBuilder: (c) => [countItem(c.totalCount, 'Records')],
      itemBuilder: (context, r) => AttendanceCard(
        record: r,
        onTap: () =>
            pushManagerPage(context, ManagerAttendanceDetailScreen(record: r)),
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({super.key, required this.record, this.onTap});

  final AttendanceRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final hrDiffers =
        r.attendanceStatus != null && r.attendanceStatus != r.status;
    String punch(DateTime? t) => t == null ? '—' : MFormat.time(t);

    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManagerAvatar(name: r.displayName, size: 38),
          const SizedBox(width: MSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MText.cardTitle,
                      ),
                    ),
                    const SizedBox(width: MSpace.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: StatusChip(r.status, dense: true),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  MFormat.weekdayDate(r.attendanceDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta,
                ),
                const SizedBox(height: 2),
                Text(
                  'In ${punch(r.checkIn)}  ·  Out ${punch(r.checkOut)}'
                  '${hrDiffers ? '  ·  HR: ${r.attendanceStatus}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta.copyWith(color: MColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
