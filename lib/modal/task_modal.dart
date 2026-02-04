// To parse this JSON data:
//
//     final employeeTaskModal = employeeTaskModalFromJson(jsonString);

import 'dart:convert';

EmployeeTaskModal employeeTaskModalFromJson(String str) =>
    EmployeeTaskModal.fromJson(json.decode(str));

String employeeTaskModalToJson(EmployeeTaskModal data) =>
    json.encode(data.toJson());

class EmployeeTaskModal {
  final Message message;

  EmployeeTaskModal({required this.message});

  factory EmployeeTaskModal.fromJson(Map<String, dynamic> json) =>
      EmployeeTaskModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  final String status;
  final String message;
  final List<Datum> data;
  final int code;

  Message({
    required this.status,
    required this.message,
    required this.data,
    required this.code,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"] ?? "",
    message: json["message"] ?? "",
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    code: json["code"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "code": code,
  };
}

class Datum {
  String name;
  String subject;
  String status;
  String? customCustomer;
  String customAssignedTo;
  DateTime expStartDate;
  DateTime expEndDate;
  String? description;
  String? customRemarks;

  Datum({
    required this.name,
    required this.subject,
    required this.status,
    this.customCustomer,
    required this.customAssignedTo,
    required this.expStartDate,
    required this.expEndDate,
    this.description,
    this.customRemarks,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    name: json["name"] ?? "",
    subject: json["subject"] ?? "",
    status: json["status"] ?? "",
    customCustomer: json["custom_customer"], // nullable allowed
    customAssignedTo: json["custom_assigned_to"] ?? "",
    expStartDate: DateTime.parse(json["exp_start_date"]),
    expEndDate: DateTime.parse(json["exp_end_date"]),
    description: json["description"], // API returns null -> OK
    customRemarks: json["custom_remarks"], // API returns null -> OK
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "subject": subject,
    "status": status,
    "custom_customer": customCustomer,
    "custom_assigned_to": customAssignedTo,
    "exp_start_date":
        "${expStartDate.year.toString().padLeft(4, '0')}-${expStartDate.month.toString().padLeft(2, '0')}-${expStartDate.day.toString().padLeft(2, '0')}",
    "exp_end_date":
        "${expEndDate.year.toString().padLeft(4, '0')}-${expEndDate.month.toString().padLeft(2, '0')}-${expEndDate.day.toString().padLeft(2, '0')}",
    "description": description,
    "custom_remarks": customRemarks,
  };
}
