import 'package:location_tracker_app/modal/manager/json_utils.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';

// ---------------------------------------------------------------------------
// Attendance detail
// ---------------------------------------------------------------------------

class AttendanceDetail {
  final String employee;
  final String employeeName;
  final String? salesPerson;
  final DateTime? date;
  final List<CheckinLog> logs;
  final HrAttendance? attendance;

  const AttendanceDetail({
    required this.employee,
    required this.employeeName,
    required this.salesPerson,
    required this.date,
    required this.logs,
    required this.attendance,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'];
    return AttendanceDetail(
      employee: asString(json['employee']),
      employeeName: asString(json['employee_name']),
      salesPerson: asStringOrNull(json['sales_person']),
      date: asDateTime(json['date']),
      logs: asMapList(json['logs']).map(CheckinLog.fromJson).toList(),
      attendance: att is Map ? HrAttendance.fromJson(asMap(att)) : null,
    );
  }
}

class CheckinLog {
  final String name;
  final String logType;
  final DateTime? time;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const CheckinLog({
    required this.name,
    required this.logType,
    required this.time,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  bool get isIn => logType.toUpperCase() == 'IN';
  bool get hasLocation =>
      isValidCoordinate(latitude) && isValidCoordinate(longitude);

  factory CheckinLog.fromJson(Map<String, dynamic> json) => CheckinLog(
    name: asString(json['name']),
    logType: asString(json['log_type']).toUpperCase(),
    time: asDateTime(json['time']),
    deviceId: asStringOrNull(json['device_id']),
    latitude: asDoubleOrNull(json['latitude']),
    longitude: asDoubleOrNull(json['longitude']),
    locationName: asStringOrNull(json['location_name']),
  );
}

class HrAttendance {
  final String name;
  final String status;
  final String? leaveType;
  final double? workingHours;
  final DateTime? inTime;
  final DateTime? outTime;

  const HrAttendance({
    required this.name,
    required this.status,
    required this.leaveType,
    required this.workingHours,
    required this.inTime,
    required this.outTime,
  });

  factory HrAttendance.fromJson(Map<String, dynamic> json) => HrAttendance(
    name: asString(json['name']),
    status: asString(json['status']),
    leaveType: asStringOrNull(json['leave_type']),
    workingHours: asDoubleOrNull(json['working_hours']),
    inTime: asDateTime(json['in_time']),
    outTime: asDateTime(json['out_time']),
  );
}

// ---------------------------------------------------------------------------
// Transaction detail (Sales Order / Sales Invoice incl. returns / Payment Entry)
// ---------------------------------------------------------------------------

class TransactionDoctype {
  static const salesOrder = 'Sales Order';
  static const salesInvoice = 'Sales Invoice';
  static const paymentEntry = 'Payment Entry';
}

class TransactionDetail {
  // Common
  final String doctype;
  final String name;
  final String status;
  final int docstatus;
  final String? company;
  final String currency;
  final String? salesPerson;
  final String salesPersonName;
  final String? owner;
  final DateTime? creation;

  // Party
  final String customer;
  final String customerName;

  // Dates
  final DateTime? transactionDate;
  final DateTime? deliveryDate;
  final DateTime? postingDate;
  final DateTime? dueDate;

  // Sales Order / Invoice
  final bool isReturn;
  final String? returnAgainst;
  final String? returnReason;
  final double? total;
  final double? totalTaxesAndCharges;
  final double? grandTotal;
  final double? roundedTotal;
  final double? outstandingAmount;
  final String? paymentStatus;
  final double? perDelivered;
  final double? perBilled;

  // Payment Entry
  final String? paymentType;
  final String? modeOfPayment;
  final double? paidAmount;
  final double? unallocatedAmount;
  final String? referenceNo;
  final DateTime? referenceDate;
  final String? remarks;

  // Child tables
  final List<TxnItem> items;
  final List<TxnTax> taxes;
  final List<TxnSalesTeam> salesTeam;
  final List<TxnPayment> payments;
  final List<TxnReturn> returns;
  final List<TxnReference> references;

  const TransactionDetail({
    required this.doctype,
    required this.name,
    required this.status,
    required this.docstatus,
    required this.company,
    required this.currency,
    required this.salesPerson,
    required this.salesPersonName,
    required this.owner,
    required this.creation,
    required this.customer,
    required this.customerName,
    required this.transactionDate,
    required this.deliveryDate,
    required this.postingDate,
    required this.dueDate,
    required this.isReturn,
    required this.returnAgainst,
    required this.returnReason,
    required this.total,
    required this.totalTaxesAndCharges,
    required this.grandTotal,
    required this.roundedTotal,
    required this.outstandingAmount,
    required this.paymentStatus,
    required this.perDelivered,
    required this.perBilled,
    required this.paymentType,
    required this.modeOfPayment,
    required this.paidAmount,
    required this.unallocatedAmount,
    required this.referenceNo,
    required this.referenceDate,
    required this.remarks,
    required this.items,
    required this.taxes,
    required this.salesTeam,
    required this.payments,
    required this.returns,
    required this.references,
  });

  bool get isSalesOrder => doctype == TransactionDoctype.salesOrder;
  bool get isSalesInvoice => doctype == TransactionDoctype.salesInvoice;
  bool get isPaymentEntry => doctype == TransactionDoctype.paymentEntry;

  String get customerDisplay =>
      customerName.isNotEmpty ? customerName : customer;

  factory TransactionDetail.fromJson(Map<String, dynamic> json) =>
      TransactionDetail(
        doctype: asString(json['doctype']),
        name: asString(json['name']),
        status: asStringOrNull(json['status']) ?? 'Draft',
        docstatus: asInt(json['docstatus']),
        company: asStringOrNull(json['company']),
        currency: asStringOrNull(json['currency']) ?? 'INR',
        salesPerson: asStringOrNull(json['sales_person']),
        salesPersonName: asString(json['sales_person_name']),
        owner: asStringOrNull(json['owner']),
        creation: asDateTime(json['creation']),
        customer: asString(json['customer']),
        customerName: asString(json['customer_name']).trim(),
        transactionDate: asDateTime(json['transaction_date']),
        deliveryDate: asDateTime(json['delivery_date']),
        postingDate: asDateTime(json['posting_date']),
        dueDate: asDateTime(json['due_date']),
        isReturn: asFlag(json['is_return']),
        returnAgainst: asStringOrNull(json['return_against']),
        returnReason: asStringOrNull(json['return_reason']),
        total: asDoubleOrNull(json['total']),
        totalTaxesAndCharges: asDoubleOrNull(json['total_taxes_and_charges']),
        grandTotal: asDoubleOrNull(json['grand_total']),
        roundedTotal: asDoubleOrNull(json['rounded_total']),
        outstandingAmount: asDoubleOrNull(json['outstanding_amount']),
        paymentStatus: asStringOrNull(json['payment_status']),
        perDelivered: asDoubleOrNull(json['per_delivered']),
        perBilled: asDoubleOrNull(json['per_billed']),
        paymentType: asStringOrNull(json['payment_type']),
        modeOfPayment: asStringOrNull(json['mode_of_payment']),
        paidAmount: asDoubleOrNull(json['paid_amount']),
        unallocatedAmount: asDoubleOrNull(json['unallocated_amount']),
        referenceNo: asStringOrNull(json['reference_no']),
        referenceDate: asDateTime(json['reference_date']),
        remarks: asStringOrNull(json['remarks']),
        items: asMapList(json['items']).map(TxnItem.fromJson).toList(),
        taxes: asMapList(json['taxes']).map(TxnTax.fromJson).toList(),
        salesTeam: asMapList(
          json['sales_team'],
        ).map(TxnSalesTeam.fromJson).toList(),
        payments: asMapList(json['payments']).map(TxnPayment.fromJson).toList(),
        returns: asMapList(json['returns']).map(TxnReturn.fromJson).toList(),
        references: asMapList(
          json['references'],
        ).map(TxnReference.fromJson).toList(),
      );
}

class TxnItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final double rate;
  final double amount;

  const TxnItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.rate,
    required this.amount,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  factory TxnItem.fromJson(Map<String, dynamic> json) => TxnItem(
    itemCode: asString(json['item_code']),
    itemName: asString(json['item_name']).trim(),
    qty: asDouble(json['qty']),
    uom: asString(json['uom']),
    rate: asDouble(json['rate']),
    amount: asDouble(json['amount']),
  );
}

class TxnTax {
  final String description;
  final double rate;
  final double taxAmount;

  const TxnTax({
    required this.description,
    required this.rate,
    required this.taxAmount,
  });

  factory TxnTax.fromJson(Map<String, dynamic> json) => TxnTax(
    description: asString(json['description']).trim(),
    rate: asDouble(json['rate']),
    taxAmount: asDouble(json['tax_amount']),
  );
}

class TxnSalesTeam {
  final String salesPerson;
  final String salesPersonName;
  final double allocatedPercentage;

  const TxnSalesTeam({
    required this.salesPerson,
    required this.salesPersonName,
    required this.allocatedPercentage,
  });

  String get displayName =>
      salesPersonName.trim().isNotEmpty ? salesPersonName.trim() : salesPerson;

  factory TxnSalesTeam.fromJson(Map<String, dynamic> json) => TxnSalesTeam(
    salesPerson: asString(json['sales_person']),
    salesPersonName: asString(json['sales_person_name']),
    allocatedPercentage: asDouble(json['allocated_percentage']),
  );
}

class TxnPayment {
  final String paymentEntry;
  final DateTime? postingDate;
  final String? modeOfPayment;
  final double allocatedAmount;
  final String status;

  const TxnPayment({
    required this.paymentEntry,
    required this.postingDate,
    required this.modeOfPayment,
    required this.allocatedAmount,
    required this.status,
  });

  factory TxnPayment.fromJson(Map<String, dynamic> json) => TxnPayment(
    paymentEntry: asString(json['payment_entry']),
    postingDate: asDateTime(json['posting_date']),
    modeOfPayment: asStringOrNull(json['mode_of_payment']),
    allocatedAmount: asDouble(json['allocated_amount']),
    status: asString(json['status']),
  );
}

class TxnReturn {
  final String name;
  final DateTime? postingDate;
  final double grandTotal;

  const TxnReturn({
    required this.name,
    required this.postingDate,
    required this.grandTotal,
  });

  factory TxnReturn.fromJson(Map<String, dynamic> json) => TxnReturn(
    name: asString(json['name']),
    postingDate: asDateTime(json['posting_date']),
    grandTotal: asDouble(json['grand_total']),
  );
}

class TxnReference {
  final String referenceDoctype;
  final String referenceName;
  final double totalAmount;
  final double outstandingAmount;
  final double allocatedAmount;

  const TxnReference({
    required this.referenceDoctype,
    required this.referenceName,
    required this.totalAmount,
    required this.outstandingAmount,
    required this.allocatedAmount,
  });

  bool get isSalesInvoice =>
      referenceDoctype == TransactionDoctype.salesInvoice &&
      referenceName.isNotEmpty;

  factory TxnReference.fromJson(Map<String, dynamic> json) => TxnReference(
    referenceDoctype: asString(json['reference_doctype']),
    referenceName: asString(json['reference_name']),
    totalAmount: asDouble(json['total_amount']),
    outstandingAmount: asDouble(json['outstanding_amount']),
    allocatedAmount: asDouble(json['allocated_amount']),
  );
}
