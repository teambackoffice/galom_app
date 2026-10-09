import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:provider/provider.dart';

/// Switches the shell to [module]. When [range] is given (e.g. the dashboard
/// period) the module list is filtered to it so its numbers match the tile.
void openManagerModule(
  BuildContext context,
  ManagerModule module, {
  DateTimeRange? range,
}) {
  final nav = context.read<ManagerNavController>();

  void applyRange<T>() {
    if (range == null) return;
    context.read<ManagerListController<T>>().setDateRange(range);
  }

  switch (module) {
    case ManagerModule.attendance:
      applyRange<AttendanceRecord>();
      nav.goTo(ManagerTab.attendance);
    case ManagerModule.visits:
      applyRange<CustomerVisit>();
      nav.goTo(ManagerTab.visits);
    case ManagerModule.salesOrders:
      applyRange<SalesOrderRecord>();
      nav.goToSales(SalesTab.orders);
    case ManagerModule.salesReturns:
      applyRange<SalesReturnRecord>();
      nav.goToSales(SalesTab.returns);
    case ManagerModule.salesInvoices:
      applyRange<SalesInvoiceRecord>();
      nav.goToSales(SalesTab.invoices);
    case ManagerModule.payments:
      applyRange<PaymentEntryRecord>();
      nav.goToSales(SalesTab.payments);
  }
}
