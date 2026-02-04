// To parse this JSON data, do
//
//     final salesInvoiceDeatailsModal = salesInvoiceDeatailsModalFromJson(jsonString);

import 'dart:convert';

SalesInvoiceDeatailsModal salesInvoiceDeatailsModalFromJson(String str) =>
    SalesInvoiceDeatailsModal.fromJson(json.decode(str));

String salesInvoiceDeatailsModalToJson(SalesInvoiceDeatailsModal data) =>
    json.encode(data.toJson());

class SalesInvoiceDeatailsModal {
  Message message;

  SalesInvoiceDeatailsModal({required this.message});

  factory SalesInvoiceDeatailsModal.fromJson(Map<String, dynamic> json) =>
      SalesInvoiceDeatailsModal(message: Message.fromJson(json["message"]));

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
  DateTime postingDate;
  String customer;
  List<Item> items;

  Data({
    required this.postingDate,
    required this.customer,
    required this.items,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    postingDate: DateTime.parse(json["posting_date"]),
    customer: json["customer"],
    items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
    "customer": customer,
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
    qty: json["qty"],
    rate: json["rate"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "item_name": itemName,
    "qty": qty,
    "rate": rate,
    "amount": amount,
  };
}
