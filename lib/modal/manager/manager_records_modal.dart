import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';

/// One salesperson-day from `get_attendance`.
class AttendanceRecord {
  final String employee;
  final String employeeName;
  final String? salesPerson;
  final String salesPersonName;
  final DateTime? attendanceDate;
  final String rawDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int logCount;
  final String? attendance;
  final String? attendanceStatus;
  final String status;

  const AttendanceRecord({
    required this.employee,
    required this.employeeName,
    required this.salesPerson,
    required this.salesPersonName,
    required this.attendanceDate,
    required this.rawDate,
    required this.checkIn,
    required this.checkOut,
    required this.logCount,
    required this.attendance,
    required this.attendanceStatus,
    required this.status,
  });

  String get displayName {
    if (salesPersonName.trim().isNotEmpty) return salesPersonName.trim();
    if (employeeName.trim().isNotEmpty) return employeeName.trim();
    return salesPersonLabel(salesPerson, null);
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        employee: asString(json['employee']),
        employeeName: asString(json['employee_name']),
        salesPerson: asStringOrNull(json['sales_person']),
        salesPersonName: asString(json['sales_person_name']),
        attendanceDate: asDateTime(json['attendance_date']),
        rawDate: asString(json['attendance_date']),
        checkIn: asDateTime(json['check_in']),
        checkOut: asDateTime(json['check_out']),
        logCount: asInt(json['log_count']),
        attendance: asStringOrNull(json['attendance']),
        attendanceStatus: asStringOrNull(json['attendance_status']),
        status: asStringOrNull(json['status']) ?? 'No Punch',
      );
}

/// One row from `get_customer_visits`. Also used as the detail model.
class CustomerVisit {
  final String name;
  final String? salesPerson;
  final String salesPersonName;
  final DateTime? date;
  final String rawTime;
  final DateTime? visitedAt;
  final String customerName;
  final String remarks;
  final double? latitude;
  final double? longitude;

  /// Place name captured with the visit (`location_name`); may be absent.
  final String? locationName;
  final DateTime? creation;
  final bool isFirstCounter;
  final bool isLastCounter;
  final String? visitPhoto;
  final String visitType;

  const CustomerVisit({
    required this.name,
    required this.salesPerson,
    required this.salesPersonName,
    required this.date,
    required this.rawTime,
    required this.visitedAt,
    required this.customerName,
    required this.remarks,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.creation,
    required this.isFirstCounter,
    required this.isLastCounter,
    required this.visitPhoto,
    required this.visitType,
  });

  String get salesPersonDisplay =>
      salesPersonLabel(salesPerson, salesPersonName);

  bool get hasLocation =>
      isValidCoordinate(latitude) && isValidCoordinate(longitude);

  factory CustomerVisit.fromJson(Map<String, dynamic> json) {
    final date = asDateTime(json['date']);
    final rawTime = asString(json['time']);
    return CustomerVisit(
      name: asString(json['name']),
      salesPerson: asStringOrNull(json['sales_person']),
      salesPersonName: asString(json['sales_person_name']),
      date: date,
      rawTime: rawTime,
      visitedAt: combineDateAndTime(date, rawTime),
      customerName: asString(json['customer_name']).trim(),
      remarks: asString(json['description']).trim(),
      latitude: asDoubleOrNull(json['latitude']),
      longitude: asDoubleOrNull(json['longitude']),
      locationName: asStringOrNull(json['location_name']),
      creation: asDateTime(json['creation']),
      isFirstCounter: asFlag(json['is_first_counter']),
      isLastCounter: asFlag(json['is_last_counter']),
      visitPhoto: asStringOrNull(json['visit_photo']),
      visitType: asString(json['visit_type']).trim(),
    );
  }
}

/// Coordinates with an absolute value below 0.001 are "no GPS" placeholders.
bool isValidCoordinate(double? v) => v != null && v.abs() >= 0.001;

class SalesOrderRecord {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? transactionDate;
  final DateTime? deliveryDate;
  final double grandTotal;
  final double roundedTotal;
  final String currency;
  final String status;
  final int docstatus;
  final double perDelivered;
  final double perBilled;
  final String? salesPerson;
  final String salesPersonName;

  const SalesOrderRecord({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.transactionDate,
    required this.deliveryDate,
    required this.grandTotal,
    required this.roundedTotal,
    required this.currency,
    required this.status,
    required this.docstatus,
    required this.perDelivered,
    required this.perBilled,
    required this.salesPerson,
    required this.salesPersonName,
  });

  String get customerDisplay =>
      customerName.isNotEmpty ? customerName : customer;
  String get salesPersonDisplay =>
      salesPersonLabel(salesPerson, salesPersonName);

  factory SalesOrderRecord.fromJson(Map<String, dynamic> json) =>
      SalesOrderRecord(
        name: asString(json['name']),
        customer: asString(json['customer']),
        customerName: asString(json['customer_name']).trim(),
        transactionDate: asDateTime(json['transaction_date']),
        deliveryDate: asDateTime(json['delivery_date']),
        grandTotal: asDouble(json['grand_total']),
        roundedTotal: asDouble(json['rounded_total']),
        currency: asStringOrNull(json['currency']) ?? 'INR',
        status: asStringOrNull(json['status']) ?? 'Draft',
        docstatus: asInt(json['docstatus']),
        perDelivered: asDouble(json['per_delivered']),
        perBilled: asDouble(json['per_billed']),
        salesPerson: asStringOrNull(json['sales_person']),
        salesPersonName: asString(json['sales_person_name']),
      );
}

/// A credit note (Sales Invoice with is_return = 1). Amounts are negative.
class SalesReturnRecord {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? postingDate;
  final String? returnAgainst;
  final String? returnReason;
  final double grandTotal;
  final double roundedTotal;
  final String currency;
  final String status;
  final int docstatus;
  final String? salesPerson;
  final String salesPersonName;

  const SalesReturnRecord({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.returnAgainst,
    required this.returnReason,
    required this.grandTotal,
    required this.roundedTotal,
    required this.currency,
    required this.status,
    required this.docstatus,
    required this.salesPerson,
    required this.salesPersonName,
  });

  String get customerDisplay =>
      customerName.isNotEmpty ? customerName : customer;
  String get salesPersonDisplay =>
      salesPersonLabel(salesPerson, salesPersonName);

  factory SalesReturnRecord.fromJson(Map<String, dynamic> json) =>
      SalesReturnRecord(
        name: asString(json['name']),
        customer: asString(json['customer']),
        customerName: asString(json['customer_name']).trim(),
        postingDate: asDateTime(json['posting_date']),
        returnAgainst: asStringOrNull(json['return_against']),
        returnReason: asStringOrNull(json['return_reason']),
        grandTotal: asDouble(json['grand_total']),
        roundedTotal: asDouble(json['rounded_total']),
        currency: asStringOrNull(json['currency']) ?? 'INR',
        status: asStringOrNull(json['status']) ?? 'Draft',
        docstatus: asInt(json['docstatus']),
        salesPerson: asStringOrNull(json['sales_person']),
        salesPersonName: asString(json['sales_person_name']),
      );
}

class SalesInvoiceRecord {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? postingDate;
  final DateTime? dueDate;
  final double grandTotal;
  final double roundedTotal;
  final double outstandingAmount;
  final String currency;
  final String status;
  final int docstatus;
  final String? salesPerson;
  final String salesPersonName;
  final String paymentStatus;

  const SalesInvoiceRecord({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.roundedTotal,
    required this.outstandingAmount,
    required this.currency,
    required this.status,
    required this.docstatus,
    required this.salesPerson,
    required this.salesPersonName,
    required this.paymentStatus,
  });

  String get customerDisplay =>
      customerName.isNotEmpty ? customerName : customer;
  String get salesPersonDisplay =>
      salesPersonLabel(salesPerson, salesPersonName);

  factory SalesInvoiceRecord.fromJson(Map<String, dynamic> json) {
    final status = asStringOrNull(json['status']) ?? 'Draft';
    return SalesInvoiceRecord(
      name: asString(json['name']),
      customer: asString(json['customer']),
      customerName: asString(json['customer_name']).trim(),
      postingDate: asDateTime(json['posting_date']),
      dueDate: asDateTime(json['due_date']),
      grandTotal: asDouble(json['grand_total']),
      roundedTotal: asDouble(json['rounded_total']),
      outstandingAmount: asDouble(json['outstanding_amount']),
      currency: asStringOrNull(json['currency']) ?? 'INR',
      status: status,
      docstatus: asInt(json['docstatus']),
      salesPerson: asStringOrNull(json['sales_person']),
      salesPersonName: asString(json['sales_person_name']),
      paymentStatus: asStringOrNull(json['payment_status']) ?? status,
    );
  }
}

class PaymentEntryRecord {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? postingDate;
  final double paidAmount;
  final double unallocatedAmount;
  final String? modeOfPayment;
  final String? referenceNo;
  final DateTime? referenceDate;
  final String status;
  final int docstatus;
  final String? salesPerson;
  final String salesPersonName;
  final List<String> linkedInvoices;

  const PaymentEntryRecord({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.paidAmount,
    required this.unallocatedAmount,
    required this.modeOfPayment,
    required this.referenceNo,
    required this.referenceDate,
    required this.status,
    required this.docstatus,
    required this.salesPerson,
    required this.salesPersonName,
    required this.linkedInvoices,
  });

  String get customerDisplay =>
      customerName.isNotEmpty ? customerName : customer;
  String get salesPersonDisplay =>
      salesPersonLabel(salesPerson, salesPersonName);

  factory PaymentEntryRecord.fromJson(Map<String, dynamic> json) =>
      PaymentEntryRecord(
        name: asString(json['name']),
        customer: asString(json['customer']),
        customerName: asString(json['customer_name']).trim(),
        postingDate: asDateTime(json['posting_date']),
        paidAmount: asDouble(json['paid_amount']),
        unallocatedAmount: asDouble(json['unallocated_amount']),
        modeOfPayment: asStringOrNull(json['mode_of_payment']),
        referenceNo: asStringOrNull(json['reference_no']),
        referenceDate: asDateTime(json['reference_date']),
        status: asStringOrNull(json['status']) ?? 'Draft',
        docstatus: asInt(json['docstatus']),
        salesPerson: asStringOrNull(json['sales_person']),
        salesPersonName: asString(json['sales_person_name']),
        linkedInvoices: asStringList(json['linked_invoices']),
      );
}
