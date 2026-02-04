// To parse this JSON data, do
//
//     final salesOrderModal = salesOrderModalFromJson(jsonString);

import 'dart:convert';

SalesOrderModal salesOrderModalFromJson(String str) =>
    SalesOrderModal.fromJson(json.decode(str));

String salesOrderModalToJson(SalesOrderModal data) =>
    json.encode(data.toJson());

class SalesOrderModal {
  Message message;

  SalesOrderModal({required this.message});

  factory SalesOrderModal.fromJson(Map<String, dynamic> json) =>
      SalesOrderModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  List<SalesOrder> salesOrders;

  Message({required this.status, required this.salesOrders});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"],
    salesOrders: List<SalesOrder>.from(
      json["sales_orders"].map((x) => SalesOrder.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "sales_orders": List<dynamic>.from(salesOrders.map((x) => x.toJson())),
  };
}

class SalesOrder {
  String name;
  String customer;
  DateTime deliveryDate;
  double totalAmount;
  double totalTaxAmount;
  double grandTotal;
  double roundedTotal;

  List<Item> items;

  SalesOrder({
    required this.name,
    required this.customer,
    required this.deliveryDate,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.grandTotal,
    required this.roundedTotal,
    required this.items,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
    name: json["name"],
    customer: json["customer"],
    deliveryDate: DateTime.parse(json["delivery_date"]),
    totalAmount: json["total"],
    totalTaxAmount: json["total_taxes_and_charges"],
    grandTotal: json["grand_total"],
    roundedTotal: json["rounded total"],
    items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "customer": customer,
    "delivery_date":
        "${deliveryDate.year.toString().padLeft(4, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}",
    "Total": totalAmount,
    "total_tax_amount": totalTaxAmount,
    "grand_total": grandTotal,
    "rounded total": roundedTotal,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class Item {
  String itemCode;
  double qty;
  double rate;
  double amount;

  Item({
    required this.itemCode,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    itemCode: json["item_code"],
    qty: json["qty"],
    rate: json["rate"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "qty": qty,
    "rate": rate,
    "amount": amount,
  };
}
