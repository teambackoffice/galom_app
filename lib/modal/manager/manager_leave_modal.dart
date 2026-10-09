import 'package:location_tracker_app/modal/manager/json_utils.dart';

/// Leave Application row from `galom.galom.leave_api.get_leave_application`.
class LeaveApplication {
  final String name;
  final String employee;
  final String employeeName;
  final String leaveType;
  final String? department;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool halfDay;
  final DateTime? halfDayDate;
  final double totalLeaveDays;
  final String? reason;
  final double? leaveBalance;
  final String? leaveApproverName;
  final DateTime? postingDate;
  final String status;
  final int docstatus;

  const LeaveApplication({
    required this.name,
    required this.employee,
    required this.employeeName,
    required this.leaveType,
    required this.department,
    required this.fromDate,
    required this.toDate,
    required this.halfDay,
    required this.halfDayDate,
    required this.totalLeaveDays,
    required this.reason,
    required this.leaveBalance,
    required this.leaveApproverName,
    required this.postingDate,
    required this.status,
    required this.docstatus,
  });

  String get displayName =>
      employeeName.trim().isNotEmpty ? employeeName.trim() : employee;

  /// Open and not yet submitted: the manager can still approve or reject.
  bool get isPending => status == 'Open' && docstatus == 0;

  /// Status shown to the user ("Open" reads as "Pending").
  String get displayStatus {
    if (docstatus == 2) return 'Cancelled';
    if (status == 'Open') return 'Pending';
    return status.isEmpty ? 'Pending' : status;
  }

  LeaveApplication copyWith({String? status, int? docstatus}) =>
      LeaveApplication(
        name: name,
        employee: employee,
        employeeName: employeeName,
        leaveType: leaveType,
        department: department,
        fromDate: fromDate,
        toDate: toDate,
        halfDay: halfDay,
        halfDayDate: halfDayDate,
        totalLeaveDays: totalLeaveDays,
        reason: reason,
        leaveBalance: leaveBalance,
        leaveApproverName: leaveApproverName,
        postingDate: postingDate,
        status: status ?? this.status,
        docstatus: docstatus ?? this.docstatus,
      );

  factory LeaveApplication.fromJson(Map<String, dynamic> json) =>
      LeaveApplication(
        name: asString(json['name']),
        employee: asString(json['employee']),
        employeeName: asString(json['employee_name']),
        leaveType: asStringOrNull(json['leave_type']) ?? 'Leave',
        department: asStringOrNull(json['department']),
        fromDate: asDateTime(json['from_date']),
        toDate: asDateTime(json['to_date']),
        halfDay: asFlag(json['half_day']),
        halfDayDate: asDateTime(json['half_day_date']),
        totalLeaveDays: asDouble(json['total_leave_days']),
        reason: asStringOrNull(json['description']),
        leaveBalance: asDoubleOrNull(json['leave_balance']),
        leaveApproverName: asStringOrNull(json['leave_approver_name']),
        postingDate: asDateTime(json['posting_date']),
        status: asString(json['status']).trim(),
        docstatus: asInt(json['docstatus']),
      );
}
