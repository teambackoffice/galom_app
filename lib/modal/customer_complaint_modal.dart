class ComplaintOptions {
  static const statuses = ['Open', 'In Progress', 'Resolved', 'Closed'];
  static const priorities = ['Low', 'Medium', 'High'];
  static const types = [
    'Product Quality',
    'Delivery',
    'Billing',
    'Pricing',
    'Service',
    'Other',
  ];
}

class CustomerComplaint {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? complaintDate;
  final String status;
  final String priority;
  final String complaintType;
  final String subject;
  final String salesPerson;
  final String raisedBy;
  final String salesInvoice;
  final String salesOrder;
  final String attachment;
  final DateTime? creation;
  // Detail-only fields
  final String description;
  final String resolution;
  final String resolvedBy;
  final DateTime? resolvedOn;

  CustomerComplaint({
    required this.name,
    required this.customer,
    required this.customerName,
    this.complaintDate,
    required this.status,
    required this.priority,
    required this.complaintType,
    required this.subject,
    required this.salesPerson,
    required this.raisedBy,
    required this.salesInvoice,
    required this.salesOrder,
    required this.attachment,
    this.creation,
    required this.description,
    required this.resolution,
    required this.resolvedBy,
    this.resolvedOn,
  });

  static String _s(dynamic v) => v == null ? '' : v.toString();
  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory CustomerComplaint.fromJson(Map<String, dynamic> j) =>
      CustomerComplaint(
        name: _s(j['name']),
        customer: _s(j['customer']),
        customerName: _s(j['customer_name']),
        complaintDate: _d(j['complaint_date']),
        status: _s(j['status']),
        priority: _s(j['priority']),
        complaintType: _s(j['complaint_type']),
        subject: _s(j['subject']),
        salesPerson: _s(j['sales_person']),
        raisedBy: _s(j['raised_by']),
        salesInvoice: _s(j['sales_invoice']),
        salesOrder: _s(j['sales_order']),
        attachment: _s(j['attachment']),
        creation: _d(j['creation']),
        description: _s(j['description']),
        resolution: _s(j['resolution']),
        resolvedBy: _s(j['resolved_by']),
        resolvedOn: _d(j['resolved_on']),
      );

  String get displayCustomer =>
      customerName.isNotEmpty ? customerName : customer;

  bool get isImageAttachment {
    final lower = attachment.toLowerCase();
    return const ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic']
        .any(lower.endsWith);
  }
}

class CustomerComplaintList {
  final int count;
  final List<CustomerComplaint> complaints;

  CustomerComplaintList({required this.count, required this.complaints});

  factory CustomerComplaintList.fromJson(Map<String, dynamic> j) {
    final raw = j['complaints'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => CustomerComplaint.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CustomerComplaint>[];
    return CustomerComplaintList(
      count: int.tryParse('${j['count']}') ?? list.length,
      complaints: list,
    );
  }
}

class CreateComplaintRequest {
  final String customer;
  final String subject;
  final String description;
  final String status; // Open | In Progress | Resolved | Closed
  final String? priority; // Low | Medium | High
  final String? complaintType;
  final String? complaintDate; // YYYY-MM-DD
  final String? resolution;
  final String? salesInvoice;
  final String? salesOrder;

  CreateComplaintRequest({
    required this.customer,
    required this.subject,
    required this.description,
    this.status = 'Open',
    this.priority,
    this.complaintType,
    this.complaintDate,
    this.resolution,
    this.salesInvoice,
    this.salesOrder,
  });

  Map<String, String> toJson() => {
        'customer': customer,
        'subject': subject,
        'description': description,
        'status': status,
        if (priority != null) 'priority': priority!,
        if (complaintType != null) 'complaint_type': complaintType!,
        if (complaintDate != null) 'complaint_date': complaintDate!,
        if (resolution != null) 'resolution': resolution!,
        if (salesInvoice != null) 'sales_invoice': salesInvoice!,
        if (salesOrder != null) 'sales_order': salesOrder!,
      };
}
