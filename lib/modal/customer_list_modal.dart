// To parse this JSON data, do
//
//     final customerListModal = customerListModalFromJson(jsonString);

import 'dart:convert';

CustomerListModal customerListModalFromJson(String str) =>
    CustomerListModal.fromJson(json.decode(str));

String customerListModalToJson(CustomerListModal data) =>
    json.encode(data.toJson());

class CustomerListModal {
  CustomerListModalMessage message;

  CustomerListModal({required this.message});

  factory CustomerListModal.fromJson(Map<String, dynamic> json) =>
      CustomerListModal(
        message: CustomerListModalMessage.fromJson(json["message"]),
      );

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class CustomerListModalMessage {
  List<MessageElement> message;

  CustomerListModalMessage({required this.message});

  factory CustomerListModalMessage.fromJson(Map<String, dynamic> json) =>
      CustomerListModalMessage(
        message: List<MessageElement>.from(
          json["message"].map((x) => MessageElement.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "message": List<dynamic>.from(message.map((x) => x.toJson())),
  };
}

class MessageElement {
  String name;
  String customerName;
  String customerType;
  String? customerGroup;
  String? territory;
  String? mobileNo;
  String? emailId;
  String? gstin;
  bool hasGstin;

  MessageElement({
    required this.name,
    required this.customerName,
    required this.customerType,
    required this.customerGroup,
    required this.territory,
    required this.mobileNo,
    required this.emailId,
    required this.gstin,
    required this.hasGstin,
  });

  factory MessageElement.fromJson(Map<String, dynamic> json) => MessageElement(
    name: json["name"],
    customerName: json["customer_name"],
    customerType: json["customer_type"],
    customerGroup: json["customer_group"] ?? '',
    territory: json["territory"] ?? '',
    mobileNo: json["mobile_no"] ?? '',
    emailId: json["email_id"] ?? '',
    gstin: json["gstin"] ?? '',
    hasGstin: json["has_gstin"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "customer_name": customerName,
    "customer_type": customerType,
    "customer_group": customerGroup,
    "territory": territory,
    "mobile_no": mobileNo,
    "email_id": emailId,
    "gstin": gstin,
    "has_gstin": hasGstin,
  };
}
