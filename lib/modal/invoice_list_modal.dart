// To parse this JSON data, do
//
//     final invoiceListModal = invoiceListModalFromJson(jsonString);

import 'dart:convert';

InvoiceListModal invoiceListModalFromJson(String str) =>
    InvoiceListModal.fromJson(json.decode(str));

String invoiceListModalToJson(InvoiceListModal data) =>
    json.encode(data.toJson());

class InvoiceListModal {
  Message message;

  InvoiceListModal({required this.message});

  factory InvoiceListModal.fromJson(Map<String, dynamic> json) =>
      InvoiceListModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  List<Invoice> invoices;

  Message({required this.invoices});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    invoices: List<Invoice>.from(
      json["invoices"].map((x) => Invoice.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "invoices": List<dynamic>.from(invoices.map((x) => x.toJson())),
  };
}

class Invoice {
  String invoiceId;
  String customer;
  DateTime postingDate;
  DateTime dueDate;
  double grandTotal;
  double outstandingAmount;
  String status;
  List<Item> items;
  List<Payment> payments;

  Invoice({
    required this.invoiceId,
    required this.customer,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
    required this.items,
    required this.payments,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    invoiceId: json["invoice_id"],
    customer: json["customer"],
    postingDate: DateTime.parse(json["posting_date"]),
    dueDate: DateTime.parse(json["due_date"]),
    grandTotal: json["grand_total"].toDouble(),
    outstandingAmount: json["outstanding_amount"].toDouble(),
    status: json["status"],
    items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
    payments: List<Payment>.from(
      json["payments"].map((x) => Payment.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "invoice_id": invoiceId,
    "customer": customer,
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
    "due_date":
        "${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}",
    "grand_total": grandTotal,
    "outstanding_amount": outstandingAmount,
    "status": status,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
    "payments": List<dynamic>.from(payments.map((x) => x.toJson())),
  };
}

class Item {
  String itemCode;
  String itemName;
  double qty;
  double rate;
  double amount;
  String description;

  Item({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
    required this.description,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    itemCode: json["item_code"],
    itemName: json["item_name"],
    qty: json["qty"].toDouble(),
    rate: json["rate"].toDouble(),
    amount: json["amount"].toDouble(),
    description: json["description"],
  );

  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "item_name": itemName,
    "qty": qty,
    "rate": rate,
    "amount": amount,
    "description": description,
  };
}

class Payment {
  String paymentEntry;
  DateTime postingDate;
  String? modeOfPayment;
  double paidAmount;
  double allocatedAmount;
  String status;

  Payment({
    required this.paymentEntry,
    required this.postingDate,
    this.modeOfPayment,
    required this.paidAmount,
    required this.allocatedAmount,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    paymentEntry: json["payment_entry"],
    postingDate: DateTime.parse(json["posting_date"]),
    modeOfPayment: json["mode_of_payment"],
    paidAmount: json["paid_amount"].toDouble(),
    allocatedAmount: json["allocated_amount"].toDouble(),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "payment_entry": paymentEntry,
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
    "mode_of_payment": modeOfPayment,
    "paid_amount": paidAmount,
    "allocated_amount": allocatedAmount,
    "status": status,
  };
}
