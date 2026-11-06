// Model for sales_pilot.Api.targets.get_my_monthly_target (`data` payload).
// Every field is parsed defensively: numbers may be int or double, and any
// field may be null or of an unexpected type.

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v == null ? '' : v.toString();

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

class MyTargetModal {
  final String salesPerson;
  final String salesPersonName;
  final String month;
  final String monthLabel;
  final String fromDate;
  final String toDate;
  final String fiscalYear;
  final bool hasTarget;
  final double targetAmount;
  final double achievedAmount;
  final double remainingAmount;
  final double excessAmount;
  final double achievementPercent;
  final double invoicedNetTotal;
  final double invoicedGrandTotal;
  final double collectedAmount;
  final int invoiceCount;
  final int returnCount;
  final int daysInMonth;
  final int daysLeft;
  final double requiredPerDay;
  final List<TargetRow> targets;
  final List<TargetInvoice> invoices;

  MyTargetModal({
    required this.salesPerson,
    required this.salesPersonName,
    required this.month,
    required this.monthLabel,
    required this.fromDate,
    required this.toDate,
    required this.fiscalYear,
    required this.hasTarget,
    required this.targetAmount,
    required this.achievedAmount,
    required this.remainingAmount,
    required this.excessAmount,
    required this.achievementPercent,
    required this.invoicedNetTotal,
    required this.invoicedGrandTotal,
    required this.collectedAmount,
    required this.invoiceCount,
    required this.returnCount,
    required this.daysInMonth,
    required this.daysLeft,
    required this.requiredPerDay,
    required this.targets,
    required this.invoices,
  });

  factory MyTargetModal.fromJson(Map<String, dynamic> json) {
    final rawTargets = json['targets'];
    final rawInvoices = json['invoices'];
    return MyTargetModal(
      salesPerson: _toStr(json['sales_person']),
      salesPersonName: _toStr(json['sales_person_name']),
      month: _toStr(json['month']),
      monthLabel: _toStr(json['month_label']),
      fromDate: _toStr(json['from_date']),
      toDate: _toStr(json['to_date']),
      fiscalYear: _toStr(json['fiscal_year']),
      hasTarget: _toBool(json['has_target']),
      targetAmount: _toDouble(json['target_amount']),
      achievedAmount: _toDouble(json['achieved_amount']),
      remainingAmount: _toDouble(json['remaining_amount']),
      excessAmount: _toDouble(json['excess_amount']),
      achievementPercent: _toDouble(json['achievement_percent']),
      invoicedNetTotal: _toDouble(json['invoiced_net_total']),
      invoicedGrandTotal: _toDouble(json['invoiced_grand_total']),
      collectedAmount: _toDouble(json['collected_amount']),
      invoiceCount: _toInt(json['invoice_count']),
      returnCount: _toInt(json['return_count']),
      daysInMonth: _toInt(json['days_in_month']),
      daysLeft: _toInt(json['days_left']),
      requiredPerDay: _toDouble(json['required_per_day']),
      targets: rawTargets is List
          ? rawTargets
                .whereType<Map>()
                .map((e) => TargetRow.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      invoices: rawInvoices is List
          ? rawInvoices
                .whereType<Map>()
                .map(
                  (e) => TargetInvoice.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
    );
  }
}

class TargetRow {
  final String itemGroup;
  final String distributionId;
  final double monthPercentage;
  final double annualTargetAmount;
  final double targetAmount;
  final double achievedAmount;
  final double remainingAmount;

  TargetRow({
    required this.itemGroup,
    required this.distributionId,
    required this.monthPercentage,
    required this.annualTargetAmount,
    required this.targetAmount,
    required this.achievedAmount,
    required this.remainingAmount,
  });

  factory TargetRow.fromJson(Map<String, dynamic> json) => TargetRow(
    itemGroup: _toStr(json['item_group']),
    distributionId: _toStr(json['distribution_id']),
    monthPercentage: _toDouble(json['month_percentage']),
    annualTargetAmount: _toDouble(json['annual_target_amount']),
    targetAmount: _toDouble(json['target_amount']),
    achievedAmount: _toDouble(json['achieved_amount']),
    remainingAmount: _toDouble(json['remaining_amount']),
  );
}

class TargetInvoice {
  final String name;
  final String postingDate;
  final String customer;
  final String customerName;
  final bool isReturn;
  final double netTotal;
  final double grandTotal;
  final double outstandingAmount;
  final String status;

  TargetInvoice({
    required this.name,
    required this.postingDate,
    required this.customer,
    required this.customerName,
    required this.isReturn,
    required this.netTotal,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
  });

  factory TargetInvoice.fromJson(Map<String, dynamic> json) {
    final isReturn = _toBool(json['is_return']);
    // Returns should always display as negative, whatever sign the API sends.
    double signed(dynamic v) {
      final d = _toDouble(v);
      return isReturn ? -d.abs() : d;
    }

    return TargetInvoice(
      name: _toStr(json['name']),
      postingDate: _toStr(json['posting_date']),
      customer: _toStr(json['customer']),
      customerName: _toStr(json['customer_name']),
      isReturn: isReturn,
      netTotal: signed(json['net_total']),
      grandTotal: signed(json['grand_total']),
      outstandingAmount: signed(json['outstanding_amount']),
      status: _toStr(json['status']),
    );
  }
}
