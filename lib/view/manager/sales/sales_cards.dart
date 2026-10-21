import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';

/// One layout for every sales document, so the eye always finds things in
/// the same place:
///
///   Customer name ..................... ₹ amount
///   DOC-NO · 01 Oct 2026 ............... [status]
///   Salesperson · module detail ........ (note)
class _TxnCard extends StatelessWidget {
  const _TxnCard({
    required this.customer,
    required this.amount,
    required this.docNo,
    required this.date,
    required this.status,
    required this.salesPerson,
    this.amountColor,
    this.detail,
    this.note,
    this.noteColor,
    this.onTap,
  });

  final String customer;
  final String amount;
  final Color? amountColor;
  final String docNo;
  final DateTime? date;
  final String status;
  final String salesPerson;
  final String? detail;
  final String? note;
  final Color? noteColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.cardTitle,
                ),
              ),
              const SizedBox(width: MSpace.sm),
              Text(
                amount,
                style: MText.amount.copyWith(fontSize: 15, color: amountColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$docNo  ·  ${MFormat.date(date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta,
                ),
              ),
              const SizedBox(width: MSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: StatusChip(status, dense: true),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  detail == null ? salesPerson : '$salesPerson  ·  $detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta.copyWith(color: MColors.textMuted),
                ),
              ),
              if (note != null) ...[
                const SizedBox(width: MSpace.sm),
                Text(
                  note!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: noteColor ?? MColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SalesOrderCard extends StatelessWidget {
  const SalesOrderCard({super.key, required this.order, this.onTap});

  final SalesOrderRecord order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return _TxnCard(
      onTap: onTap,
      customer: o.customerDisplay,
      amount: MFormat.money(o.grandTotal),
      docNo: o.name,
      date: o.transactionDate,
      status: o.status,
      salesPerson: o.salesPersonDisplay,
      detail: o.deliveryDate == null
          ? null
          : 'Deliver by ${MFormat.shortDate(o.deliveryDate)}',
      note: o.docstatus == 1
          ? '${MFormat.percent(o.perDelivered)} delivered'
          : null,
    );
  }
}

class SalesReturnCard extends StatelessWidget {
  const SalesReturnCard({super.key, required this.salesReturn, this.onTap});

  final SalesReturnRecord salesReturn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = salesReturn;
    final detail = [
      if (r.returnAgainst != null) 'Against ${r.returnAgainst}',
      if (r.returnReason != null) r.returnReason!,
    ];
    return _TxnCard(
      onTap: onTap,
      customer: r.customerDisplay,
      // ERPNext stores returns as negative; keep the sign visible.
      amount: MFormat.money(r.grandTotal),
      amountColor: MColors.purple,
      docNo: r.name,
      date: r.postingDate,
      status: r.status,
      salesPerson: r.salesPersonDisplay,
      detail: detail.isEmpty ? null : detail.join(' · '),
    );
  }
}

class SalesInvoiceCard extends StatelessWidget {
  const SalesInvoiceCard({super.key, required this.invoice, this.onTap});

  final SalesInvoiceRecord invoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    final submitted = i.docstatus == 1;
    final due = i.outstandingAmount > 0;
    return _TxnCard(
      onTap: onTap,
      customer: i.customerDisplay,
      amount: MFormat.money(i.grandTotal),
      docNo: i.name,
      date: i.postingDate,
      // Overdue / Credit Note Issued say more than the payment status.
      status: i.status == 'Overdue' || i.status == 'Credit Note Issued'
          ? i.status
          : i.paymentStatus,
      salesPerson: i.salesPersonDisplay,
      detail: i.dueDate == null ? null : 'Due ${MFormat.shortDate(i.dueDate)}',
      note: !submitted
          ? null
          : due
          ? '${MFormat.money(i.outstandingAmount)} due'
          : 'Settled',
      noteColor: !due
          ? MColors.green
          : (i.status == 'Overdue' ? MColors.red : MColors.orange),
    );
  }
}

class PaymentEntryCard extends StatelessWidget {
  const PaymentEntryCard({super.key, required this.payment, this.onTap});

  final PaymentEntryRecord payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final n = p.linkedInvoices.length;
    final detail = [
      if (p.modeOfPayment != null) p.modeOfPayment!,
      if (p.referenceNo != null) 'Ref ${p.referenceNo}',
    ];
    return _TxnCard(
      onTap: onTap,
      customer: p.customerDisplay,
      amount: MFormat.money(p.paidAmount),
      amountColor: p.docstatus == 1 ? MColors.green : null,
      docNo: p.name,
      date: p.postingDate,
      status: p.status,
      salesPerson: p.salesPersonDisplay,
      detail: detail.isEmpty ? null : detail.join(' · '),
      note: n == 0 ? null : '$n invoice${n == 1 ? '' : 's'}',
    );
  }
}
