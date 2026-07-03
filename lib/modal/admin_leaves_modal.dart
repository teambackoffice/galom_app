class AdminLeaveApplicationModalClassResponse {
  final Message message;

  AdminLeaveApplicationModalClassResponse({required this.message});

  factory AdminLeaveApplicationModalClassResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminLeaveApplicationModalClassResponse(
      message: Message.fromJson(json['message']),
    );
  }
}

class Message {
  final String status;
  final List<AdminLeaveApplicationModalClass> applications;

  Message({required this.status, required this.applications});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      status: json['status'] ?? '',
      applications: (json['applications'] as List<dynamic>)
          .map((e) => AdminLeaveApplicationModalClass.fromJson(e))
          .toList(),
    );
  }
}

class AdminLeaveApplicationModalClass {
  final String name;
  final String employee;
  final String employeeName;
  final String leaveType;
  final String company;
  final String? department;
  final String fromDate;
  final String toDate;
  final int halfDay;
  final String? halfDayDate;
  final double totalLeaveDays;
  final String? description;
  final double leaveBalance;
  final String? leaveApprover;
  final String? leaveApproverName;
  final int followViaEmail;
  final String postingDate;
  final String status;
  final int docstatus;
  final String owner;
  final String creation;
  final String modified;
  final String modifiedBy;

  AdminLeaveApplicationModalClass({
    required this.name,
    required this.employee,
    required this.employeeName,
    required this.leaveType,
    required this.company,
    this.department,
    required this.fromDate,
    required this.toDate,
    required this.halfDay,
    this.halfDayDate,
    required this.totalLeaveDays,
    this.description,
    required this.leaveBalance,
    this.leaveApprover,
    this.leaveApproverName,
    required this.followViaEmail,
    required this.postingDate,
    required this.status,
    required this.docstatus,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
  });

  factory AdminLeaveApplicationModalClass.fromJson(Map<String, dynamic> json) {
    return AdminLeaveApplicationModalClass(
      name: json['name'] ?? '',
      employee: json['employee'] ?? '',
      employeeName: json['employee_name'] ?? '',
      leaveType: json['leave_type'] ?? '',
      company: json['company'] ?? '',
      department: json['department'],
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      halfDay: json['half_day'] ?? 0,
      halfDayDate: json['half_day_date'],
      totalLeaveDays: (json['total_leave_days'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      leaveBalance: (json['leave_balance'] as num?)?.toDouble() ?? 0.0,
      leaveApprover: json['leave_approver'],
      leaveApproverName: json['leave_approver_name'],
      followViaEmail: json['follow_via_email'] ?? 0,
      postingDate: json['posting_date'] ?? '',
      status: json['status'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      owner: json['owner'] ?? '',
      creation: json['creation'] ?? '',
      modified: json['modified'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
    );
  }
}
