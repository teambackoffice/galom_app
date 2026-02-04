class SalesInvoiceIdsModel {
  final String status;
  final int code;
  final String message;
  final List<SalesInvoiceData> invoices;

  SalesInvoiceIdsModel({
    required this.status,
    required this.code,
    required this.message,
    required this.invoices,
  });

  factory SalesInvoiceIdsModel.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] ?? {};
    return SalesInvoiceIdsModel(
      status: msg['status'] ?? '',
      code: msg['code'] ?? 0,
      message: msg['message'] ?? '',
      invoices: (msg['data'] as List<dynamic>? ?? [])
          .map((item) => SalesInvoiceData.fromJson(item))
          .toList(),
    );
  }
}

class SalesInvoiceData {
  final String name;
  final String customer;
  final double outstandingAmount;

  SalesInvoiceData({
    required this.name,
    required this.customer,
    required this.outstandingAmount,
  });

  factory SalesInvoiceData.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceData(
      name: json['name'] ?? '',
      customer: json['customer'] ?? '',
      outstandingAmount: (json['outstanding_amount'] ?? 0).toDouble(),
    );
  }
}
