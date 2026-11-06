String _s(dynamic v) => v == null ? '' : v.toString();
String? _sOrNull(dynamic v) {
  final s = _s(v).trim();
  return s.isEmpty ? null : s;
}

/// The line's type for display: the typed-in name when the type is Others.
String expenseTypeLabel(String type, String? otherType) =>
    type == 'Others' && otherType != null && otherType.isNotEmpty
        ? otherType
        : type;
double _n(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
DateTime? _d(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) =>
    raw is List
        ? raw.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList()
        : <T>[];

/// `approval_status` shown to the employee: Draft means waiting for approval.
String expenseStatusLabel(String approvalStatus) =>
    approvalStatus == 'Draft' || approvalStatus.isEmpty
        ? 'Pending'
        : approvalStatus;

class ExpenseClaim {
  final String name;
  final DateTime? postingDate;
  final double totalClaimedAmount;
  final double totalSanctionedAmount;
  final double totalAdvanceAmount;
  final double totalTaxesAndCharges;
  final double grandTotal;
  final String approvalStatus;
  final String status;
  final int docstatus;

  ExpenseClaim.fromJson(Map<String, dynamic> j)
      : name = _s(j['name']),
        postingDate = _d(j['posting_date']),
        totalClaimedAmount = _n(j['total_claimed_amount']),
        totalSanctionedAmount = _n(j['total_sanctioned_amount']),
        totalAdvanceAmount = _n(j['total_advance_amount']),
        totalTaxesAndCharges = _n(j['total_taxes_and_charges']),
        grandTotal = _n(j['grand_total']),
        approvalStatus = _s(j['approval_status']),
        status = _s(j['status']),
        docstatus = _i(j['docstatus']);

  String get statusLabel => expenseStatusLabel(approvalStatus);
}

class ExpenseLine {
  final DateTime? expenseDate;
  final String expenseType;
  final String? otherExpenseType;
  final String description;
  final double amount;
  final double sanctionedAmount;
  final String? receipt; // private file_url of this line's receipt

  ExpenseLine.fromJson(Map<String, dynamic> j)
      : expenseDate = _d(j['expense_date']),
        expenseType = _s(j['expense_type']),
        otherExpenseType = _sOrNull(j['other_expense_type']),
        description = _s(j['description']),
        amount = _n(j['amount']),
        sanctionedAmount = _n(j['sanctioned_amount']),
        receipt = _sOrNull(j['receipt']);

  String get typeLabel => expenseTypeLabel(expenseType, otherExpenseType);
}

class ExpenseAttachment {
  final String fileUrl;
  final String fileName;

  ExpenseAttachment.fromJson(Map<String, dynamic> j)
      : fileUrl = _s(j['file_url']),
        fileName = _s(j['file_name']);

  bool get isImage {
    final lower = (fileName.isNotEmpty ? fileName : fileUrl).toLowerCase();
    return const ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic']
        .any(lower.endsWith);
  }
}

class ExpenseClaimDetail {
  final String name;
  final String employee;
  final String employeeName;
  final DateTime? postingDate;
  final String company;
  final String approvalStatus;
  final String status;
  final int docstatus;
  final double totalClaimedAmount;
  final double totalSanctionedAmount;
  final double totalTaxesAndCharges;
  final double totalAdvanceAmount;
  final double grandTotal;
  final String expenseApprover;
  final List<ExpenseLine> expenses;
  final List<ExpenseAttachment> attachments;

  ExpenseClaimDetail.fromJson(Map<String, dynamic> j)
      : name = _s(j['name']),
        employee = _s(j['employee']),
        employeeName = _s(j['employee_name']),
        postingDate = _d(j['posting_date']),
        company = _s(j['company']),
        approvalStatus = _s(j['approval_status']),
        status = _s(j['status']),
        docstatus = _i(j['docstatus']),
        totalClaimedAmount = _n(j['total_claimed_amount']),
        totalSanctionedAmount = _n(j['total_sanctioned_amount']),
        totalTaxesAndCharges = _n(j['total_taxes_and_charges']),
        totalAdvanceAmount = _n(j['total_advance_amount']),
        grandTotal = _n(j['grand_total']),
        expenseApprover = _s(j['expense_approver']),
        expenses = _list(j['expenses'], ExpenseLine.fromJson),
        attachments = _list(j['attachments'], ExpenseAttachment.fromJson);

  String get statusLabel => expenseStatusLabel(approvalStatus);
}

class ExpenseSummary {
  final int year;
  final double total;
  final double pending;
  final double approved;
  final double rejected;

  ExpenseSummary.fromJson(Map<String, dynamic> j)
      : year = _i(j['year']),
        total = _n(j['total']),
        pending = _n(j['pending']),
        approved = _n(j['approved']),
        rejected = _n(j['rejected']);
}

class NewExpenseLine {
  final String expenseType;
  final String? otherExpenseType; // required when expenseType == 'Others'
  final double amount;
  final String? expenseDate; // YYYY-MM-DD
  final String? description;

  /// Local photo sent as `receipt_<n>`; never part of [toJson].
  final String? receiptPath;

  NewExpenseLine({
    required this.expenseType,
    required this.amount,
    this.otherExpenseType,
    this.expenseDate,
    this.description,
    this.receiptPath,
  });

  String get typeLabel => expenseTypeLabel(expenseType, otherExpenseType);

  NewExpenseLine withReceipt(String? path) => NewExpenseLine(
        expenseType: expenseType,
        amount: amount,
        otherExpenseType: otherExpenseType,
        expenseDate: expenseDate,
        description: description,
        receiptPath: path,
      );

  Map<String, dynamic> toJson() => {
        'expense_type': expenseType,
        if (expenseType == 'Others') 'other_expense_type': otherExpenseType,
        'amount': amount,
        if (expenseDate != null) 'expense_date': expenseDate,
        if (description != null) 'description': description,
      };
}

/// Result of `create_expense_claim`.
class CreatedExpenseClaim {
  final String name;
  final String approvalStatus;
  final double totalClaimedAmount;

  CreatedExpenseClaim.fromJson(Map<String, dynamic> j)
      : name = _s(j['name']),
        approvalStatus = _s(j['approval_status']),
        totalClaimedAmount = _n(j['total_claimed_amount']);
}

/// An expense saved on the device only. Saved expenses are later merged and
/// sent to the server as one claim.
class SavedExpense {
  final String id;
  final DateTime savedAt;
  final List<NewExpenseLine> lines;
  final List<String> receiptPaths;
  final String? remark;

  SavedExpense({
    required this.id,
    required this.savedAt,
    required this.lines,
    this.receiptPaths = const [],
    this.remark,
  });

  double get total => lines.fold(0, (sum, l) => sum + l.amount);

  /// Every local photo: per-line receipts plus claim-level attachments.
  List<String> get allFilePaths => [
        ...lines.map((l) => l.receiptPath).whereType<String>(),
        ...receiptPaths,
      ];

  SavedExpense.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        savedAt = _d(j['saved_at']) ?? DateTime.now(),
        lines = _list(
          j['lines'],
          (l) => NewExpenseLine(
            expenseType: _s(l['expense_type']),
            otherExpenseType: _sOrNull(l['other_expense_type']),
            amount: _n(l['amount']),
            expenseDate: _sOrNull(l['expense_date']),
            description: _sOrNull(l['description']),
            receiptPath: _sOrNull(l['receipt_path']),
          ),
        ),
        receiptPaths = j['receipts'] is List
            ? (j['receipts'] as List).map((e) => '$e').toList()
            : const [],
        remark = j['remark'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'saved_at': savedAt.toIso8601String(),
        'lines': lines
            .map((l) => {
                  ...l.toJson(),
                  if (l.receiptPath != null) 'receipt_path': l.receiptPath,
                })
            .toList(),
        'receipts': receiptPaths,
        if (remark != null) 'remark': remark,
      };
}
