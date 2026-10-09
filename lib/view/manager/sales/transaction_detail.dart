import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_detail_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/detail_scaffold.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';

/// Detail for Sales Order, Sales Invoice (incl. returns) and Payment Entry,
/// from `get_transaction_detail`. Financial figures are shown as returned by
/// the server, never recalculated.
class ManagerTransactionDetailScreen extends StatelessWidget {
  const ManagerTransactionDetailScreen({
    super.key,
    required this.doctype,
    required this.name,
    this.service,
  });

  final String doctype;
  final String name;
  final ManagerService? service;

  String get _title => switch (doctype) {
    TransactionDoctype.salesOrder => 'Sales order',
    TransactionDoctype.paymentEntry => 'Payment entry',
    _ => 'Sales invoice',
  };

  @override
  Widget build(BuildContext context) {
    return ManagerDetailScaffold<TransactionDetail>(
      title: _title,
      loader: () => (service ?? ManagerService()).getTransactionDetail(
        doctype: doctype,
        name: name,
      ),
      builder: (context, d) {
        if (d.isPaymentEntry) return _paymentEntry(context, d);
        if (d.isSalesOrder) return _salesOrder(context, d);
        return _salesInvoice(context, d);
      },
    );
  }

  static void _open(BuildContext context, String doctype, String name) {
    pushManagerPage(
      context,
      ManagerTransactionDetailScreen(doctype: doctype, name: name),
    );
  }

  // ---------------------------------------------------------------------------

  List<Widget> _salesOrder(BuildContext context, TransactionDetail d) => [
    DetailHeroCard(
      overline: 'Sales order',
      title: d.name,
      subtitle: d.customerDisplay,
      status: StatusChip(d.status),
      amountLabel: 'Grand total',
      amount: MFormat.money(d.grandTotal),
      footer: d.docstatus == 1
          ? Row(
              children: [
                Expanded(
                  child: _HeroProgress('Delivered', d.perDelivered ?? 0),
                ),
                const SizedBox(width: MSpace.lg),
                Expanded(child: _HeroProgress('Billed', d.perBilled ?? 0)),
              ],
            )
          : null,
    ),
    SectionCard(
      title: 'Order information',
      children: [
        _customerRow(d),
        InfoRow('Salesperson', _salesPerson(d)),
        InfoRow('Order date', MFormat.date(d.transactionDate)),
        InfoRow('Delivery date', MFormat.date(d.deliveryDate)),
        ..._commonRows(d),
      ],
    ),
    _ItemsSection(items: d.items),
    _TotalsSection(detail: d),
    if (d.taxes.isNotEmpty) _TaxesSection(taxes: d.taxes),
    if (d.salesTeam.isNotEmpty) _SalesTeamSection(team: d.salesTeam),
  ];

  List<Widget> _salesInvoice(BuildContext context, TransactionDetail d) {
    final isReturn = d.isReturn;
    return [
      DetailHeroCard(
        overline: isReturn ? 'Sales return (credit note)' : 'Sales invoice',
        title: d.name,
        subtitle: d.customerDisplay,
        status: StatusChip(isReturn ? d.status : (d.paymentStatus ?? d.status)),
        amountLabel: isReturn ? 'Return amount' : 'Invoice total',
        amount: MFormat.money(d.grandTotal),
        footer: !isReturn && d.outstandingAmount != null
            ? _HeroKeyValue('Outstanding', MFormat.money(d.outstandingAmount))
            : null,
      ),
      SectionCard(
        title: isReturn ? 'Return information' : 'Invoice information',
        children: [
          _customerRow(d),
          InfoRow('Salesperson', _salesPerson(d)),
          InfoRow('Posting date', MFormat.date(d.postingDate)),
          if (!isReturn) InfoRow('Due date', MFormat.date(d.dueDate)),
          if (!isReturn && d.paymentStatus != null)
            InfoRow('Payment status', d.paymentStatus!),
          if (!isReturn && d.paymentStatus != d.status)
            InfoRow('Document status', d.status),
          if (isReturn)
            InfoRow(
              'Against invoice',
              d.returnAgainst ?? '—',
              onTap: d.returnAgainst == null
                  ? null
                  : () => _open(
                      context,
                      TransactionDoctype.salesInvoice,
                      d.returnAgainst!,
                    ),
            ),
          if (isReturn && d.returnReason != null)
            InfoRow('Reason', d.returnReason!),
          ..._commonRows(d),
        ],
      ),
      _ItemsSection(items: d.items, isReturn: isReturn),
      _TotalsSection(detail: d),
      if (d.taxes.isNotEmpty) _TaxesSection(taxes: d.taxes),
      if (d.payments.isNotEmpty)
        SectionCard(
          title: 'Payments received',
          trailing: Text('${d.payments.length}', style: MText.meta),
          children: [
            for (final p in d.payments)
              _LinkTile(
                title: p.paymentEntry,
                subtitle: [
                  MFormat.date(p.postingDate),
                  if (p.modeOfPayment != null) p.modeOfPayment!,
                ].join('  ·  '),
                amount: MFormat.money(p.allocatedAmount),
                amountColor: MColors.green,
                onTap: p.paymentEntry.isEmpty
                    ? null
                    : () => _open(
                        context,
                        TransactionDoctype.paymentEntry,
                        p.paymentEntry,
                      ),
              ),
          ],
        ),
      if (d.returns.isNotEmpty)
        SectionCard(
          title: 'Returns against this invoice',
          trailing: Text('${d.returns.length}', style: MText.meta),
          children: [
            for (final r in d.returns)
              _LinkTile(
                title: r.name,
                subtitle: MFormat.date(r.postingDate),
                amount: MFormat.money(r.grandTotal),
                amountColor: MColors.purple,
                onTap: r.name.isEmpty
                    ? null
                    : () => _open(
                        context,
                        TransactionDoctype.salesInvoice,
                        r.name,
                      ),
              ),
          ],
        ),
      if (d.salesTeam.isNotEmpty) _SalesTeamSection(team: d.salesTeam),
    ];
  }

  List<Widget> _paymentEntry(BuildContext context, TransactionDetail d) => [
    DetailHeroCard(
      overline:
          'Payment entry${d.paymentType != null ? ' · ${d.paymentType}' : ''}',
      title: d.name,
      subtitle: d.customerDisplay,
      status: StatusChip(d.status),
      amountLabel: 'Paid amount',
      amount: MFormat.money(d.paidAmount),
      footer: (d.unallocatedAmount ?? 0) != 0
          ? _HeroKeyValue('Unallocated', MFormat.money(d.unallocatedAmount))
          : null,
    ),
    SectionCard(
      title: 'Payment information',
      children: [
        _customerRow(d),
        InfoRow('Salesperson', _salesPerson(d)),
        InfoRow('Posting date', MFormat.date(d.postingDate)),
        if (d.paymentType != null) InfoRow('Payment type', d.paymentType!),
        InfoRow('Mode of payment', d.modeOfPayment ?? '—'),
        InfoRow('Paid amount', MFormat.money(d.paidAmount), bold: true),
        if (d.unallocatedAmount != null)
          InfoRow('Unallocated', MFormat.money(d.unallocatedAmount)),
        InfoRow(
          'Reference no.',
          d.referenceNo ?? '—',
          copyable: d.referenceNo != null,
        ),
        if (d.referenceDate != null)
          InfoRow('Reference date', MFormat.date(d.referenceDate)),
        ..._commonRows(d),
      ],
    ),
    SectionCard(
      title: 'Allocated to',
      trailing: Text('${d.references.length}', style: MText.meta),
      children: [
        if (d.references.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'This payment is not allocated to any invoice.',
              style: MText.meta,
            ),
          ),
        for (final r in d.references)
          _LinkTile(
            title: r.referenceName.isNotEmpty ? r.referenceName : '—',
            subtitle:
                '${r.referenceDoctype}  ·  Total ${MFormat.money(r.totalAmount)}  ·  Outstanding ${MFormat.money(r.outstandingAmount)}',
            amount: MFormat.money(r.allocatedAmount),
            amountColor: MColors.green,
            onTap: r.isSalesInvoice
                ? () => _open(
                    context,
                    TransactionDoctype.salesInvoice,
                    r.referenceName,
                  )
                : null,
          ),
      ],
    ),
    if (d.remarks != null)
      SectionCard(
        title: 'Remarks',
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(d.remarks!, style: MText.body),
          ),
        ],
      ),
  ];

  // ---------------------------------------------------------------------------

  static Widget _customerRow(TransactionDetail d) => InfoRow(
    'Customer',
    d.customerName.isNotEmpty &&
            d.customer.isNotEmpty &&
            d.customerName != d.customer
        ? '${d.customerName}\n${d.customer}'
        : d.customerDisplay,
  );

  static String _salesPerson(TransactionDetail d) {
    if (d.salesPersonName.trim().isNotEmpty) return d.salesPersonName.trim();
    return d.salesPerson ?? 'Unassigned';
  }

  static List<Widget> _commonRows(TransactionDetail d) => [
    if (d.company != null) InfoRow('Company', d.company!),
    if (d.owner != null) InfoRow('Created by', d.owner!),
    if (d.creation != null) InfoRow('Created on', MFormat.dateTime(d.creation)),
  ];
}

class _HeroProgress extends StatelessWidget {
  const _HeroProgress(this.label, this.percent);
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label  ${MFormat.percent(percent)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 5,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _HeroKeyValue extends StatelessWidget {
  const _HeroKeyValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MSpace.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: MSpace.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items, this.isReturn = false});
  final List<TxnItem> items;
  final bool isReturn;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: isReturn ? 'Returned items' : 'Items',
      trailing: Text('${items.length}', style: MText.meta),
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('No items.', style: MText.meta),
          ),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: MColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].displayName,
                        style: MText.cardTitle.copyWith(fontSize: 14),
                      ),
                      if (items[i].itemCode.isNotEmpty &&
                          items[i].itemCode != items[i].displayName)
                        Text(items[i].itemCode, style: MText.docNo),
                      const SizedBox(height: 3),
                      Text(
                        '${MFormat.qty(items[i].qty)} ${items[i].uom}  ×  ${MFormat.money(items[i].rate)}',
                        style: MText.meta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MSpace.md),
                Text(
                  MFormat.money(items[i].amount),
                  style: MText.amount.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.detail});
  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final showRounded =
        d.roundedTotal != null &&
        d.roundedTotal != 0 &&
        d.roundedTotal != d.grandTotal;
    return SectionCard(
      title: 'Totals',
      children: [
        if (d.total != null) InfoRow('Net total', MFormat.money(d.total)),
        if (d.totalTaxesAndCharges != null)
          InfoRow('Taxes & charges', MFormat.money(d.totalTaxesAndCharges)),
        InfoRow('Grand total', MFormat.money(d.grandTotal), bold: true),
        if (showRounded)
          InfoRow('Rounded total', MFormat.money(d.roundedTotal), bold: true),
        if (d.isSalesInvoice && !d.isReturn && d.outstandingAmount != null)
          InfoRow(
            'Outstanding',
            MFormat.money(d.outstandingAmount),
            bold: true,
            valueColor: (d.outstandingAmount ?? 0) > 0
                ? MColors.orange
                : MColors.green,
          ),
      ],
    );
  }
}

class _TaxesSection extends StatelessWidget {
  const _TaxesSection({required this.taxes});
  final List<TxnTax> taxes;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Taxes',
      children: [
        for (final t in taxes)
          InfoRow(
            t.rate != 0
                ? '${t.description.isNotEmpty ? t.description : 'Tax'} (${MFormat.percent(t.rate)})'
                : (t.description.isNotEmpty ? t.description : 'Tax'),
            MFormat.money(t.taxAmount),
          ),
      ],
    );
  }
}

class _SalesTeamSection extends StatelessWidget {
  const _SalesTeamSection({required this.team});
  final List<TxnSalesTeam> team;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sales team',
      children: [
        for (final s in team)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ManagerAvatar(name: s.displayName, size: 30),
                const SizedBox(width: MSpace.md),
                Expanded(child: Text(s.displayName, style: MText.body)),
                Text(
                  MFormat.percent(s.allocatedPercentage),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.amountColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color? amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MSpace.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: onTap != null
                          ? MColors.accent
                          : MColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: MText.meta),
                ],
              ),
            ),
            const SizedBox(width: MSpace.sm),
            Text(
              amount,
              style: MText.amount.copyWith(fontSize: 14, color: amountColor),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: MColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
