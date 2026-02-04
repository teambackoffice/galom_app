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
    status: json["status"],
    code: json["code"],
    message: json["message"],
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
  DateTime modified;
  String modifiedBy;
  int docstatus;
  String idx;
  String locationUpdateInterval;
  String doctype;

  Data({
    required this.name,
    required this.owner,
    required this.modified,
    required this.modifiedBy,
    required this.docstatus,
    required this.idx,
    required this.locationUpdateInterval,
    required this.doctype,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"],
    owner: json["owner"],
    modified: DateTime.parse(json["modified"]),
    modifiedBy: json["modified_by"],
    docstatus: json["docstatus"],
    idx: json["idx"],
    locationUpdateInterval: json["location_update_interval"],
    doctype: json["doctype"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "owner": owner,
    "modified": modified.toIso8601String(),
    "modified_by": modifiedBy,
    "docstatus": docstatus,
    "idx": idx,
    "location_update_interval": locationUpdateInterval,
    "doctype": doctype,
  };
}
