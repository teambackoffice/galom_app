import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_detail_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/view/manager/sales/sales_cards.dart';
import 'package:location_tracker_app/view/manager/sales/transaction_detail.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/tabbed_page.dart';
import 'package:location_tracker_app/view/manager/widgets/module_list_view.dart';
import 'package:provider/provider.dart';

extension SalesTabModule on SalesTab {
  ManagerModule get module => switch (this) {
    SalesTab.orders => ManagerModule.salesOrders,
    SalesTab.returns => ManagerModule.salesReturns,
    SalesTab.invoices => ManagerModule.salesInvoices,
    SalesTab.payments => ManagerModule.payments,
  };
}

/// Sales tab: Orders, Returns, Invoices and Payments.
class ManagerSalesHub extends StatelessWidget {
  const ManagerSalesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerTabbedPage(
      title: 'Sales',
      subtitle: 'Orders, returns, invoices and collections',
      indexOf: (nav) => nav.salesTab.index,
      onIndex: (nav, i) => nav.setSalesTab(SalesTab.values[i]),
      tabs: const [
        ManagerTabSpec('Orders', SalesOrdersList()),
        ManagerTabSpec('Returns', SalesReturnsList()),
        ManagerTabSpec('Invoices', SalesInvoicesList()),
        ManagerTabSpec('Payments', PaymentEntriesList()),
      ],
    );
  }
}

void _openDetail(BuildContext context, String doctype, String name) {
  pushManagerPage(
    context,
    ManagerTransactionDetailScreen(doctype: doctype, name: name),
  );
}

class SalesOrdersList extends StatelessWidget {
  const SalesOrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<SalesOrderRecord>(
      controller: context.read<ManagerListController<SalesOrderRecord>>(),
      searchHint: 'Search order no. or customer',
      statuses: const [],
      emptyIcon: ManagerModule.salesOrders.icon,
      emptyTitle: 'No sales orders',
      summaryBuilder: (c) => [
        countItem(c.totalCount, 'Orders'),
        SummaryItem('Order value', MFormat.money(c.totals['grand_total'] ?? 0)),
      ],
      itemBuilder: (context, o) => SalesOrderCard(
        order: o,
        onTap: () =>
            _openDetail(context, TransactionDoctype.salesOrder, o.name),
      ),
    );
  }
}

class SalesReturnsList extends StatelessWidget {
  const SalesReturnsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<SalesReturnRecord>(
      controller: context.read<ManagerListController<SalesReturnRecord>>(),
      searchHint: 'Search return no. or customer',
      statuses: const [],
      emptyIcon: ManagerModule.salesReturns.icon,
      emptyTitle: 'No sales returns',
      summaryBuilder: (c) => [
        countItem(c.totalCount, 'Returns'),
        SummaryItem(
          'Return amount',
          MFormat.money(c.totals['grand_total'] ?? 0),
          color: MColors.purple,
        ),
      ],
      itemBuilder: (context, r) => SalesReturnCard(
        salesReturn: r,
        // Returns are Sales Invoices with is_return = 1.
        onTap: () =>
            _openDetail(context, TransactionDoctype.salesInvoice, r.name),
      ),
    );
  }
}

class SalesInvoicesList extends StatelessWidget {
  const SalesInvoicesList({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<SalesInvoiceRecord>(
      controller: context.read<ManagerListController<SalesInvoiceRecord>>(),
      searchHint: 'Search invoice no. or customer',
      statuses: const [],
      emptyIcon: ManagerModule.salesInvoices.icon,
      emptyTitle: 'No sales invoices',
      summaryBuilder: (c) => [
        countItem(c.totalCount, 'Invoices'),
        SummaryItem(
          'Billed',
          MFormat.moneyCompact(c.totals['grand_total'] ?? 0),
        ),
        SummaryItem(
          'Outstanding',
          MFormat.moneyCompact(c.totals['outstanding_amount'] ?? 0),
          color: MColors.orange,
        ),
      ],
      itemBuilder: (context, i) => SalesInvoiceCard(
        invoice: i,
        onTap: () =>
            _openDetail(context, TransactionDoctype.salesInvoice, i.name),
      ),
    );
  }
}

class PaymentEntriesList extends StatelessWidget {
  const PaymentEntriesList({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<PaymentEntryRecord>(
      controller: context.read<ManagerListController<PaymentEntryRecord>>(),
      searchHint: 'Search entry, customer or ref no.',
      statuses: const [],
      emptyIcon: ManagerModule.payments.icon,
      emptyTitle: 'No customer payments',
      summaryBuilder: (c) => [
        countItem(c.totalCount, 'Receipts'),
        SummaryItem(
          'Collected',
          MFormat.money(c.totals['paid_amount'] ?? 0),
          color: MColors.green,
        ),
      ],
      itemBuilder: (context, p) => PaymentEntryCard(
        payment: p,
        onTap: () =>
            _openDetail(context, TransactionDoctype.paymentEntry, p.name),
      ),
    );
  }
}
