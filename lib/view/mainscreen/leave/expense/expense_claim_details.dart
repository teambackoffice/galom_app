import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/expense_claim_controller.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';
import 'package:location_tracker_app/service/customer_complaint_service.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/expense_style.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:provider/provider.dart';

class ExpenseClaimDetailsPage extends StatefulWidget {
  final String claimName;

  const ExpenseClaimDetailsPage({super.key, required this.claimName});

  @override
  State<ExpenseClaimDetailsPage> createState() =>
      _ExpenseClaimDetailsPageState();
}

class _ExpenseClaimDetailsPageState extends State<ExpenseClaimDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseClaimController>().fetchDetail(widget.claimName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExpenseClaimController>();
    final c = ctrl.detail;

    Widget body;
    if (ctrl.isDetailLoading || (c == null && ctrl.detailError == null)) {
      body = const Center(
        child: CircularProgressIndicator(color: ComplaintStyle.navy),
      );
    } else if (c == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: ExpenseStyle.rejected,
              ),
              const SizedBox(height: 12),
              Text(
                ctrl.detailError ?? 'Claim not found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ComplaintStyle.navy),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ctrl.fetchDetail(widget.claimName),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ComplaintStyle.navy,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        color: ComplaintStyle.navy,
        onRefresh: () => ctrl.fetchDetail(widget.claimName),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _buildHeader(c),
            const SizedBox(height: 14),
            _section(
              icon: Icons.list_alt_rounded,
              title: 'Expenses (${c.expenses.length})',
              child: c.expenses.isEmpty
                  ? const Text(
                      '-',
                      style: TextStyle(color: ComplaintStyle.muted),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < c.expenses.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 20,
                              color: ComplaintStyle.border,
                            ),
                          _buildLine(c.expenses[i], c.approvalStatus),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _section(
              icon: Icons.calculate_outlined,
              title: 'Totals',
              child: Column(
                children: [
                  _amountRow('Claimed', c.totalClaimedAmount),
                  _amountRow('Sanctioned', c.totalSanctionedAmount),
                  if (c.totalTaxesAndCharges != 0)
                    _amountRow('Taxes & charges', c.totalTaxesAndCharges),
                  if (c.totalAdvanceAmount != 0)
                    _amountRow('Advance', c.totalAdvanceAmount),
                  const Divider(height: 18, color: ComplaintStyle.border),
                  _amountRow('Grand total', c.grandTotal, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
              icon: Icons.info_outline_rounded,
              title: 'Details',
              child: Column(
                children: [
                  _row('Employee', c.employeeName.isNotEmpty
                      ? c.employeeName
                      : c.employee),
                  _row('Posting Date',
                      ComplaintStyle.formatDate(c.postingDate)),
                  _row('Approver', c.expenseApprover),
                  _row('Company', c.company),
                  _row('Document Status', c.status),
                ],
              ),
            ),
            if (c.attachments.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(
                icon: Icons.receipt_rounded,
                title: 'Receipts (${c.attachments.length})',
                child: _buildReceipts(c.attachments, ctrl.sid),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: ComplaintAppBar(
        title: 'Expense Claim',
        subtitle: widget.claimName,
      ),
      body: body,
    );
  }

  Widget _buildHeader(ExpenseClaimDetail c) {
    final label = c.statusLabel;
    final color = ExpenseStyle.statusColor(label);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ComplaintStyle.navy, Color(0xFF1F3A73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ComplaintStyle.navy.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ExpenseStyle.statusIcon(label), size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                ComplaintStyle.formatDate(c.postingDate),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Claimed amount',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            ExpenseStyle.money(c.totalClaimedAmount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (c.approvalStatus == 'Approved' &&
              c.totalSanctionedAmount != c.totalClaimedAmount) ...[
            const SizedBox(height: 4),
            Text(
              'Sanctioned ${ExpenseStyle.money(c.totalSanctionedAmount)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF81C784),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLine(ExpenseLine l, String approvalStatus) {
    final showSanctioned =
        approvalStatus == 'Approved' && l.sanctionedAmount != l.amount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ComplaintStyle.navy.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            ExpenseStyle.typeIcon(l.expenseType),
            size: 18,
            color: ComplaintStyle.navy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.expenseType.isEmpty ? 'Expense' : l.expenseType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ComplaintStyle.navy,
                ),
              ),
              if (l.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  l.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                ComplaintStyle.formatDate(l.expenseDate),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: ComplaintStyle.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ExpenseStyle.money(l.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ComplaintStyle.navy,
              ),
            ),
            if (showSanctioned)
              Text(
                ExpenseStyle.money(l.sanctionedAmount),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ExpenseStyle.approved,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceipts(List<ExpenseAttachment> files, String? sid) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: files.map((f) {
        final url = CustomerComplaintService.attachmentUrl(f.fileUrl);
        if (!f.isImage) {
          return Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ComplaintStyle.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  color: ComplaintStyle.navy,
                ),
                const SizedBox(height: 6),
                Text(
                  f.fileName.isNotEmpty ? f.fileName : f.fileUrl.split('/').last,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: ComplaintStyle.navy,
                  ),
                ),
              ],
            ),
          );
        }
        return GestureDetector(
          onTap: () => _openImage(url, sid),
          child: SizedBox(
            width: 96,
            child: ComplaintAttachmentImage(url: url, sid: sid, height: 96),
          ),
        );
      }).toList(),
    );
  }

  void _openImage(String url, String? sid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                headers: sid == null ? null : {'Cookie': 'sid=$sid'},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ComplaintStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ComplaintStyle.navy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ComplaintStyle.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? ComplaintStyle.navy : ComplaintStyle.muted,
            ),
          ),
          const Spacer(),
          Text(
            ExpenseStyle.money(value),
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: ComplaintStyle.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: ComplaintStyle.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ComplaintStyle.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
