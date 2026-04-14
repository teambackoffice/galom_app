// To parse this JSON data, do
//
//     final leaveApplicationModalClass = leaveApplicationModalClassFromJson(jsonString);

import 'dart:convert';

LeaveApplicationModalClass leaveApplicationModalClassFromJson(String str) =>
    LeaveApplicationModalClass.fromJson(json.decode(str));

String leaveApplicationModalClassToJson(LeaveApplicationModalClass data) =>
    json.encode(data.toJson());

class LeaveApplicationModalClass {
  Leavemessage message;

  LeaveApplicationModalClass({required this.message});

  factory LeaveApplicationModalClass.fromJson(Map<String, dynamic> json) =>
      LeaveApplicationModalClass(
        message: Leavemessage.fromJson(json["message"] ?? json["leavemessage"] ?? {}),
      );

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Leavemessage {
  String status;
  String employee;
  String sessionUser;
  List<Application> applications;
  MonthlyLeaveBalance monthlyLeaveBalance;

  Leavemessage({
    required this.status,
    required this.employee,
    required this.sessionUser,
    required this.applications,
    required this.monthlyLeaveBalance,
  });

  factory Leavemessage.fromJson(Map<String, dynamic> json) => Leavemessage(
    status: json["status"],
    employee: json["employee"],
    sessionUser: json["session_user"],
    applications: List<Application>.from(
      json["applications"].map((x) => Application.fromJson(x)),
    ),
    monthlyLeaveBalance: MonthlyLeaveBalance.fromJson(
      json["monthly_leave_balance"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "employee": employee,
    "session_user": sessionUser,
    "applications": List<dynamic>.from(applications.map((x) => x.toJson())),
    "monthly_leave_balance": monthlyLeaveBalance.toJson(),
  };
}

class Application {
  String name;
  String leaveType;
  DateTime fromDate;
  DateTime toDate;
  double totalLeaveDays;
  String status;
  DateTime postingDate;

  Application({
    required this.name,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalLeaveDays,
    required this.status,
    required this.postingDate,
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    name: json["name"],
    leaveType: json["leave_type"],
    fromDate: DateTime.parse(json["from_date"]),
    toDate: DateTime.parse(json["to_date"]),
    totalLeaveDays: (json["total_leave_days"] as num).toDouble(),
    status: json["status"],
    postingDate: DateTime.parse(json["posting_date"]),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "leave_type": leaveType,
    "from_date":
        "${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
    "to_date":
        "${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
    "total_leave_days": totalLeaveDays,
    "status": status,
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
  };
}

class MonthlyLeaveBalance {
  double takenThisMonth;
  double totalRemainingBalance;
  List<dynamic> leaveTypeBreakdown;

  MonthlyLeaveBalance({
    required this.takenThisMonth,
    required this.totalRemainingBalance,
    required this.leaveTypeBreakdown,
  });

  factory MonthlyLeaveBalance.fromJson(Map<String, dynamic> json) =>
      MonthlyLeaveBalance(
        takenThisMonth: (json["taken_this_month"] as num).toDouble(),
        totalRemainingBalance: (json["total_remaining_balance"] as num).toDouble(),
        leaveTypeBreakdown: List<dynamic>.from(
          json["leave_type_breakdown"].map((x) => x),
        ),
      );

  Map<String, dynamic> toJson() => {
    "taken_this_month": takenThisMonth,
    "total_remaining_balance": totalRemainingBalance,
    "leave_type_breakdown": List<dynamic>.from(
      leaveTypeBreakdown.map((x) => x),
    ),
  };
}
