// To parse this JSON data, do
//
//     final salesReturnModal = salesReturnModalFromJson(jsonString);

import 'dart:convert';

SalesReturnModal salesReturnModalFromJson(String str) =>
    SalesReturnModal.fromJson(json.decode(str));

String salesReturnModalToJson(SalesReturnModal data) =>
    json.encode(data.toJson());

class SalesReturnModal {
  Message message;

  SalesReturnModal({required this.message});

  factory SalesReturnModal.fromJson(Map<String, dynamic> json) =>
      SalesReturnModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  List<Datum> data;

  Message({required this.status, required this.data});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"],
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  String name;
  String? returnAgainst;
  String customer;
  String company;
  String postingDate;
  String? workflowState;
  String customSalesPerson;
  String? returnReason;
  List<Item> items;

  Datum({
    required this.name,
    this.returnAgainst,
    required this.customer,
    required this.company,
    required this.postingDate,
    this.workflowState,
    required this.customSalesPerson,
    this.returnReason,
    required this.items,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    name: json["name"],
    returnAgainst: json["return_against"],
    customer: json["customer"],
    company: json["company"],
    postingDate: json["posting_date"],
    workflowState: json["workflow_state"],
    customSalesPerson: json["custom_sales_person"],
    returnReason: json["custom_return_reason"],
    items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "return_against": returnAgainst,
    "customer": customer,
    "company": company,
    "posting_date": postingDate,
    "workflow_state": workflowState,
    "custom_sales_person": customSalesPerson,
    "custom_return_reason": returnReason,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class Item {
  String itemCode;
  String itemName;
  double qty;
  double rate;
  double amount;

  Item({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    itemCode: json["item_code"],
    itemName: json["item_name"],
    qty: (json["qty"] as num).toDouble(),
    rate: (json["rate"] as num).toDouble(),
    amount: (json["amount"] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "item_name": itemName,
    "qty": qty,
    "rate": rate,
    "amount": amount,
  };
}
