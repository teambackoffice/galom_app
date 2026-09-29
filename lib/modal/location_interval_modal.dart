// To parse this JSON data, do
//
//     final locationIntervalModal = locationIntervalModalFromJson(jsonString);

import 'dart:convert';

LocationIntervalModal locationIntervalModalFromJson(String str) =>
    LocationIntervalModal.fromJson(json.decode(str));

String locationIntervalModalToJson(LocationIntervalModal data) =>
    json.encode(data.toJson());

class LocationIntervalModal {
  Message message;

  LocationIntervalModal({required this.message});

  factory LocationIntervalModal.fromJson(Map<String, dynamic> json) =>
      LocationIntervalModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  int code;
  String message;
  Data data;

  Message({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"]?.toString() ?? '',
    code: (json["code"] as num?)?.toInt() ?? 0,
    message: json["message"]?.toString() ?? '',
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "code": code,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  String name;
  String owner;
  DateTime? modified;
  String? modifiedBy;
  int docstatus;
  String idx;
  // Empty when the interval is not set in "Location Update Settings"
  String locationUpdateInterval;
  String doctype;

  Data({
    required this.name,
    required this.owner,
    this.modified,
    this.modifiedBy,
    required this.docstatus,
    required this.idx,
    required this.locationUpdateInterval,
    required this.doctype,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"]?.toString() ?? '',
    owner: json["owner"]?.toString() ?? '',
    modified: json["modified"] != null
        ? DateTime.tryParse(json["modified"].toString())
        : null,
    modifiedBy: json["modified_by"]?.toString(),
    docstatus: (json["docstatus"] as num?)?.toInt() ?? 0,
    idx: json["idx"]?.toString() ?? '',
    locationUpdateInterval: json["location_update_interval"]?.toString() ?? '',
    doctype: json["doctype"]?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "owner": owner,
    "modified": modified?.toIso8601String(),
    "modified_by": modifiedBy,
    "docstatus": docstatus,
    "idx": idx,
    "location_update_interval": locationUpdateInterval,
    "doctype": doctype,
  };
}
