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

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(name: json["name"], execute: json["execute"]);

  Map<String, dynamic> toJson() => {"name": name, "execute": execute};
}
