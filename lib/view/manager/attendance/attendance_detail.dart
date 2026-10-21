import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_detail_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/detail_scaffold.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';

class ManagerAttendanceDetailScreen extends StatelessWidget {
  const ManagerAttendanceDetailScreen({
    super.key,
    required this.record,
    this.service,
  });

  final AttendanceRecord record;
  final ManagerService? service;

  @override
  Widget build(BuildContext context) {
    return ManagerDetailScaffold<AttendanceDetail>(
      title: 'Attendance',
      loader: () => (service ?? ManagerService()).getAttendanceDetail(
        employee: record.employee,
        date: record.rawDate,
      ),
      builder: (context, d) => [
        DetailHeroCard(
          overline: MFormat.weekdayDate(d.date ?? record.attendanceDate),
          title: record.displayName,
          subtitle: [
            if (d.employee.isNotEmpty) d.employee,
            if (d.employeeName.isNotEmpty &&
                d.employeeName != record.displayName)
              d.employeeName,
          ].join('  ·  '),
          status: StatusChip(record.status),
          footer: Row(
            children: [
              Expanded(child: _HeroPunch('Check-in', record.checkIn)),
              Expanded(child: _HeroPunch('Check-out', record.checkOut)),
              Expanded(child: _HeroStat('Punches', '${d.logs.length}')),
            ],
          ),
        ),
        _hrSection(d.attendance),
        SectionCard(
          title: 'Timeline',
          trailing: Text(
            '${d.logs.length} log${d.logs.length == 1 ? '' : 's'}',
            style: MText.meta,
          ),
          children: [
            if (d.logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: MSpace.lg),
                child: Text(
                  'No check-in or check-out punches for this day.',
                  style: MText.meta,
                ),
              )
            else
              for (var i = 0; i < d.logs.length; i++)
                _TimelineEntry(log: d.logs[i], isLast: i == d.logs.length - 1),
          ],
        ),
        SectionCard(
          title: 'Employee',
          children: [
            InfoRow(
              'Employee ID',
              d.employee.isNotEmpty ? d.employee : record.employee,
              copyable: true,
            ),
            if (d.employeeName.isNotEmpty)
              InfoRow('Employee name', d.employeeName),
            InfoRow('Salesperson', d.salesPerson ?? record.salesPerson ?? '—'),
          ],
        ),
      ],
    );
  }

  Widget _hrSection(HrAttendance? a) {
    if (a == null) {
      return const SectionCard(
        title: 'HR attendance',
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: MSpace.sm),
            child: Text(
              'HR has not marked attendance for this day yet.',
              style: MText.meta,
            ),
          ),
        ],
      );
    }
    return SectionCard(
      title: 'HR attendance',
      trailing: a.status.isNotEmpty ? StatusChip(a.status, dense: true) : null,
      children: [
        if (a.name.isNotEmpty) InfoRow('Record', a.name, copyable: true),
        if (a.leaveType != null) InfoRow('Leave type', a.leaveType!),
        // Shown only as reported by HR; never derived from incomplete punches.
        if (a.workingHours != null && a.workingHours! > 0)
          InfoRow('Working hours', _hours(a.workingHours!), bold: true),
        if (a.inTime != null) InfoRow('In time', MFormat.dateTime(a.inTime)),
        if (a.outTime != null) InfoRow('Out time', MFormat.dateTime(a.outTime)),
      ],
    );
  }

  static String _hours(double h) {
    final totalMinutes = (h * 60).round();
    return '${totalMinutes ~/ 60}h ${(totalMinutes % 60).toString().padLeft(2, '0')}m';
  }
}

class _HeroPunch extends StatelessWidget {
  const _HeroPunch(this.label, this.time);
  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) =>
      _HeroStat(label, time == null ? '—' : MFormat.time(time));
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.log, required this.isLast});

  final CheckinLog log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = log.isIn ? MColors.green : MColors.orange;
    final details = <String>[
      if (log.locationName != null) log.locationName!,
      if (log.hasLocation)
        '${MFormat.coordinate(log.latitude!)}, ${MFormat.coordinate(log.longitude!)}',
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: MColors.divider)),
              ],
            ),
          ),
          const SizedBox(width: MSpace.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 4 : MSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MBadge(log.isIn ? 'IN' : 'OUT', color: color),
                      const SizedBox(width: MSpace.sm),
                      Text(MFormat.time(log.time), style: MText.cardTitle),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (details.isNotEmpty)
                    MetaItem(Icons.place_outlined, details.join('  ·  '))
                  else
                    const MetaItem(
                      Icons.location_off_outlined,
                      'Location not captured',
                    ),
                  if (log.deviceId != null) ...[
                    const SizedBox(height: 2),
                    MetaItem(Icons.smartphone_rounded, log.deviceId!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
