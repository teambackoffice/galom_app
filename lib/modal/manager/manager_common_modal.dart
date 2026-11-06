import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:location_tracker_app/modal/manager/json_utils.dart';

/// The six modules a manager can review, with their API method names and
/// the status values each endpoint accepts.
enum ManagerModule {
  attendance(
    title: 'Attendance',
    method: 'get_attendance',
    statuses: ['Present', 'Absent', 'Half Day', 'On Leave', 'Work From Home'],
  ),
  visits(
    title: 'Customer Visits',
    method: 'get_customer_visits',
    statuses: ['Customer Visit', 'Check-In', 'Check-Out'],
  ),
  salesOrders(
    title: 'Sales Orders',
    method: 'get_sales_orders',
    statuses: [
      'Draft',
      'On Hold',
      'To Deliver and Bill',
      'To Bill',
      'To Deliver',
      'Completed',
      'Closed',
      'Cancelled',
    ],
  ),
  salesReturns(
    title: 'Sales Returns',
    method: 'get_sales_returns',
    statuses: ['Draft', 'Return', 'Cancelled'],
  ),
  salesInvoices(
    title: 'Sales Invoices',
    method: 'get_sales_invoices',
    statuses: [
      'Draft',
      'Unpaid',
      'Partly Paid',
      'Overdue',
      'Paid',
      'Credit Note Issued',
      'Cancelled',
    ],
  ),
  payments(
    title: 'Payment Entries',
    method: 'get_payment_entries',
    statuses: ['Draft', 'Submitted', 'Cancelled'],
  );

  const ManagerModule({
    required this.title,
    required this.method,
    required this.statuses,
  });

  final String title;
  final String method;
  final List<String> statuses;
}

/// One page of a manager list endpoint.
class ManagerPage<T> {
  final List<T> records;
  final int totalCount;
  final int start;
  final int pageLength;
  final bool hasMore;

  /// Sums over all matching rows (not just this page).
  final Map<String, double> totals;

  const ManagerPage({
    required this.records,
    required this.totalCount,
    required this.start,
    required this.pageLength,
    required this.hasMore,
    required this.totals,
  });

  factory ManagerPage.fromJson(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parse,
  ) {
    final records = asMapList(data['records']).map(parse).toList();
    return ManagerPage(
      records: records,
      totalCount: asInt(data['total_count']),
      start: asInt(data['start']),
      pageLength: asInt(data['page_length']),
      hasMore: data['has_more'] == true,
      totals: asTotals(data['totals']),
    );
  }
}

/// Query parameters shared by all six list endpoints.
class ManagerQuery {
  final String? salesPerson;
  final DateTimeRange? dateRange;
  final String? search;
  final String? status;
  final int start;
  final int pageLength;

  const ManagerQuery({
    this.salesPerson,
    this.dateRange,
    this.search,
    this.status,
    this.start = 0,
    this.pageLength = 20,
  });

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  Map<String, String> toParams() {
    final params = <String, String>{
      'start': '$start',
      'page_length': '${pageLength.clamp(1, 100)}',
    };
    if (salesPerson != null && salesPerson!.isNotEmpty) {
      params['sales_person'] = salesPerson!;
    }
    if (dateRange != null) {
      params['from_date'] = _apiDate.format(dateRange!.start);
      params['to_date'] = _apiDate.format(dateRange!.end);
    }
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (status != null && status!.isNotEmpty) params['status'] = status!;
    return params;
  }
}

class SalesPerson {
  final String name;
  final String salesPersonName;
  final String? employee;
  final bool enabled;

  const SalesPerson({
    required this.name,
    required this.salesPersonName,
    this.employee,
    this.enabled = true,
  });

  String get displayName => salesPersonName.isNotEmpty ? salesPersonName : name;

  factory SalesPerson.fromJson(Map<String, dynamic> json) => SalesPerson(
    name: asString(json['name']),
    salesPersonName: asString(json['sales_person_name']).trim(),
    employee: asStringOrNull(json['employee']),
    enabled: json['enabled'] == null ? true : asFlag(json['enabled']),
  );

  @override
  bool operator ==(Object other) => other is SalesPerson && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Picks the best label for a salesperson column.
String salesPersonLabel(String? name, String? displayName) {
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Unassigned';
}
