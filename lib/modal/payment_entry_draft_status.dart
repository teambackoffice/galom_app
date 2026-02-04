// To parse this JSON data, do
//
//     final paymentEntryDraftStatusModal = paymentEntryDraftStatusModalFromJson(jsonString);

import 'dart:convert';

PaymentEntryDraftStatusModal paymentEntryDraftStatusModalFromJson(String str) =>
    PaymentEntryDraftStatusModal.fromJson(json.decode(str));

String paymentEntryDraftStatusModalToJson(PaymentEntryDraftStatusModal data) =>
    json.encode(data.toJson());

class PaymentEntryDraftStatusModal {
  Message message;

  PaymentEntryDraftStatusModal({required this.message});

  factory PaymentEntryDraftStatusModal.fromJson(Map<String, dynamic> json) =>
      PaymentEntryDraftStatusModal(message: Message.fromJson(json["message"]));

  Map<String, dynamic> toJson() => {"message": message.toJson()};
}

class Message {
  String status;
  List<Datum> data;
  double totalAllocatedAmount;

  Message({
    required this.status,
    required this.data,
    required this.totalAllocatedAmount,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    status: json["status"],
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    totalAllocatedAmount: json["total_allocated_amount"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "total_allocated_amount": totalAllocatedAmount,
  };
}

class Datum {
  String paymentEntry;
  DateTime postingDate;
  double paidAmount;
  String? referenceNo;
  String status;
  List<Reference> references;

  Datum({
    required this.paymentEntry,
    required this.postingDate,
    required this.paidAmount,
    required this.referenceNo,
    required this.status,
    required this.references,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    paymentEntry: json["payment_entry"],
    postingDate: DateTime.parse(json["posting_date"]),
    paidAmount: json["paid_amount"],
    referenceNo: json["reference_no"],
    status: json["status"],
    references: List<Reference>.from(
      json["references"].map((x) => Reference.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "payment_entry": paymentEntry,
    "posting_date":
        "${postingDate.year.toString().padLeft(4, '0')}-${postingDate.month.toString().padLeft(2, '0')}-${postingDate.day.toString().padLeft(2, '0')}",
    "paid_amount": paidAmount,
    "reference_no": referenceNo,
    "status": status,
    "references": List<dynamic>.from(references.map((x) => x.toJson())),
  };
}

class Reference {
  String referenceDoctype;
  String referenceName;
  double allocatedAmount;

  Reference({
    required this.referenceDoctype,
    required this.referenceName,
    required this.allocatedAmount,
  });

  factory Reference.fromJson(Map<String, dynamic> json) => Reference(
    referenceDoctype: json["reference_doctype"],
    referenceName: json["reference_name"],
    allocatedAmount: json["allocated_amount"],
  );

  Map<String, dynamic> toJson() => {
    "reference_doctype": referenceDoctype,
    "reference_name": referenceName,
    "allocated_amount": allocatedAmount,
  };
}
