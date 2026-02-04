// To parse this JSON data, do
//
//     final itemsListModal = itemsListModalFromJson(jsonString);

import 'dart:convert';

ItemsListModal itemsListModalFromJson(String str) =>
    ItemsListModal.fromJson(json.decode(str));

String itemsListModalToJson(ItemsListModal data) => json.encode(data.toJson());

class ItemsListModal {
  List<Message> message;

  ItemsListModal({required this.message});

  factory ItemsListModal.fromJson(Map<String, dynamic> json) => ItemsListModal(
    message: List<Message>.from(
      json["message"].map((x) => Message.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "message": List<dynamic>.from(message.map((x) => x.toJson())),
  };
}

class Message {
  String itemCode;
  String itemName;
  String description;
  String uom;
  double price;
  int maintainStock;
  double totalStock;
  String taxTemplate;

  Message({
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.uom,
    required this.price,
    required this.totalStock,
    required this.maintainStock,
    required this.taxTemplate,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    itemCode: json["item_code"],
    itemName: json["item_name"],
    description: json["description"],
    uom: json["uom"],
    price: (json["price"] as num).toDouble(),
    maintainStock: json["maintain_stock"],
    totalStock: (json["total_stock"] as num?)?.toDouble() ?? 0.0,
    taxTemplate: json["tax_template"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "item_name": itemName,
    "description": description,
    "uom": uom,
    "price": price,
    "maintain_stock": maintainStock,
    "total_stock": totalStock,
    "tax_template": taxTemplate,
  };
}
