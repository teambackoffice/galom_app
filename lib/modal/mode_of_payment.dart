// To parse this JSON data, do
//
//     final modeOfPaymentModal = modeOfPaymentModalFromJson(jsonString);

import 'dart:convert';

ModeOfPaymentModal modeOfPaymentModalFromJson(String str) =>
    ModeOfPaymentModal.fromJson(json.decode(str));

String modeOfPaymentModalToJson(ModeOfPaymentModal data) =>
    json.encode(data.toJson());

class ModeOfPaymentModal {
  List<Message> message;

  ModeOfPaymentModal({required this.message});

  factory ModeOfPaymentModal.fromJson(Map<String, dynamic> json) =>
      ModeOfPaymentModal(
        message: List<Message>.from(
          json["message"].map((x) => Message.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "message": List<dynamic>.from(message.map((x) => x.toJson())),
  };
}

class Message {
  String name;
  bool execute;

  Message({required this.name, required this.execute});

  factory Message.fromJson(Map<String, dynamic> json) {
    bool exec = false;
    if (json["execute"] != null) {
      if (json["execute"] is bool) {
        exec = json["execute"];
      } else if (json["execute"] is int) {
        exec = json["execute"] == 1;
      }
    } else if (json["enabled"] != null) {
      if (json["enabled"] is bool) {
        exec = json["enabled"];
      } else if (json["enabled"] is int) {
        exec = json["enabled"] == 1;
      }
    }
    return Message(
      name: json["name"] ?? "",
      execute: exec,
    );
  }

  Map<String, dynamic> toJson() => {"name": name, "execute": execute};
}
