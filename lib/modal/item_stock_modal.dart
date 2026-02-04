// To parse this JSON data, do
//
//     final itemStockModal = itemStockModalFromJson(jsonString);

import 'dart:convert';

ItemStockModal itemStockModalFromJson(String str) =>
    ItemStockModal.fromJson(json.decode(str));

String itemStockModalToJson(ItemStockModal data) => json.encode(data.toJson());

class ItemStockModal {
  Message message;

  ItemStockModal({required this.message});

  factory ItemStockModal.fromJson(Map<String, dynamic> json) =>
      ItemStockModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  String message;
  List<Datum> data;
  int code;

  Message({
    required this.status,
    required this.message,
    required this.data,
    required this.code,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"],
    message: json["message"],
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    code: json["code"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "code": code,
  };
}

class Datum {
  String itemCode;
  String itemName;
  String stockUom;
  String itemGroup;
  String warehouse;
  double actualQty;

  Datum({
    required this.itemCode,
    required this.itemName,
    required this.stockUom,
    required this.itemGroup,
    required this.warehouse,
    required this.actualQty,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    itemCode: json["item_code"],
    itemName: json["item_name"],
    stockUom: json["stock_uom"],
    itemGroup: json["item_group"],
    warehouse: json["warehouse"],
    actualQty: (json["actual_qty"] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "item_name": itemName,
    "stock_uom": stockUom,
    "item_group": itemGroup,
    "warehouse": warehouse,
    "actual_qty": actualQty,
  };
}
