class PaymentEntryModal {
  Message message;

  PaymentEntryModal({required this.message});

  factory PaymentEntryModal.fromJson(Map<String, dynamic> json) =>
      PaymentEntryModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  String salesPerson;
  String customer;
  double invoiceCount;
  double totalOutstandingAmount;
  List<Invoice> invoices;

  Message({
    required this.status,
    required this.salesPerson,
    required this.customer,
    required this.invoiceCount,
    required this.totalOutstandingAmount,
    required this.invoices,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"],
    salesPerson: json["sales_person"],
    customer: json["customer"],
    invoiceCount: (json["invoice_count"] as num).toDouble(),
    totalOutstandingAmount: (json["total_outstanding_amount"] as num)
        .toDouble(),
    invoices: List<Invoice>.from(
      json["invoices"].map((x) => Invoice.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "sales_person": salesPerson,
    "customer": customer,
    "invoice_count": invoiceCount,
    "total_outstanding_amount": totalOutstandingAmount,
    "invoices": List<dynamic>.from(invoices.map((x) => x.toJson())),
  };
}

class Invoice {
  String invoiceName;
  String customer;
  DateTime postingDate;
  DateTime dueDate;
  double grandTotal;
  double outstandingAmount;
  String status;
  List<Item> items;

  Invoice({
    required this.invoiceName,
    required this.customer,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    invoiceName: json["invoice_name"],
    customer: json["customer"],
    postingDate: DateTime.parse(json["posting_date"]),
    dueDate: DateTime.parse(json["due_date"]),
    grandTotal: (json["grand_total"] as num).toDouble(),
    outstandingAmount: (json["outstanding_amount"] as num).toDouble(),
    status: json["status"],
    items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "invoice_name": invoiceName,
    "customer": customer,
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
    "due_date":
        "${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}",
    "grand_total": grandTotal,
    "outstanding_amount": outstandingAmount,
    "status": status,
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
