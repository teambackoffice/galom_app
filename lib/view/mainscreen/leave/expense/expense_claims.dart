import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/expense_claim_controller.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/create_expense_claim.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/expense_claim_details.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/expense_style.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:provider/provider.dart';

class ExpenseClaimsPage extends StatefulWidget {
  const ExpenseClaimsPage({super.key});

  @override
  State<ExpenseClaimsPage> createState() => _ExpenseClaimsPageState();
}

class _ExpenseClaimsPageState extends State<ExpenseClaimsPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<ExpenseClaimController>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ExpenseClaimController>();
      ctrl.setStatusFilter(null);
      ctrl.refresh();
      ctrl.loadSaved();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openCreate([SavedExpense? saved]) async {
    final created = await Navigator.push<CreatedExpenseClaim>(
      context,
      MaterialPageRoute(builder: (_) => CreateExpenseClaimPage(saved: saved)),
    );
    if (created != null && mounted) _showSubmitted(created);
  }

  void _showSubmitted(CreatedExpenseClaim created) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Claim ${created.name} submitted for approval '
          '(${ExpenseStyle.money(created.totalClaimedAmount)})',
        ),
        backgroundColor: ExpenseStyle.approved,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitSaved(ExpenseClaimController ctrl) async {
    final count = ctrl.savedExpenses.fold<int>(0, (n, e) => n + e.lines.length);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit as one claim?'),
        content: Text(
          '$count expense${count == 1 ? '' : 's'} totalling '
          '${ExpenseStyle.money(ctrl.savedTotal)} will be sent to your '
          'approver as a single claim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final created = await ctrl.submitSaved();
    if (!mounted) return;
    if (created != null) {
      _showSubmitted(created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.submitError ?? 'Failed to submit claim'),
          backgroundColor: ExpenseStyle.rejected,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmRemoveSaved(
    ExpenseClaimController ctrl,
    SavedExpense saved,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete saved expense?'),
        content: Text(
          '${ExpenseStyle.money(saved.total)} will be removed from this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: ExpenseStyle.rejected),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ctrl.removeSaved(saved.id);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExpenseClaimController>();

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: const ComplaintAppBar(
        title: 'Expense Claims',
        subtitle: 'Claim your work expenses',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: ComplaintStyle.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Claim',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: ComplaintStyle.navy,
        onRefresh: ctrl.refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            _buildSummary(ctrl),
            if (ctrl.savedExpenses.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSaved(ctrl),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Row(
                children: [
                  Text(
                    ctrl.statusFilter == null
                        ? 'Recent claims'
                        : '${expenseStatusLabel(ctrl.statusFilter!)} claims',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ComplaintStyle.navy,
                    ),
                  ),
                  const Spacer(),
                  if (ctrl.statusFilter != null)
                    GestureDetector(
                      onTap: () => ctrl.setStatusFilter(null),
                      child: const Text(
                        'Show all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ..._buildList(ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ExpenseClaimController ctrl) {
    final s = ctrl.summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ComplaintStyle.navy, Color(0xFF1F3A73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ComplaintStyle.navy.withOpacity(0.25),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s == null ? '—' : ExpenseStyle.money(s.total),
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total claimed in ${s?.year ?? DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryTile(ctrl, 'Pending', 'Draft', s?.pending,
                  const Color(0xFFFFB74D)),
              const SizedBox(width: 8),
              _summaryTile(ctrl, 'Approved', 'Approved', s?.approved,
                  const Color(0xFF81C784)),
              const SizedBox(width: 8),
              _summaryTile(ctrl, 'Rejected', 'Rejected', s?.rejected,
                  const Color(0xFFE57373)),
            ],
          ),
        ],
      ),
    );
  }

  /// Expenses kept on the phone, submitted together as one claim.
  Widget _buildSaved(ExpenseClaimController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ComplaintStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ExpenseStyle.pending.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.save_outlined,
                  size: 17,
                  color: ExpenseStyle.pending,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved on this phone (${ctrl.savedExpenses.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ComplaintStyle.navy,
                      ),
                    ),
                    const Text(
                      'Not submitted yet',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ComplaintStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ExpenseStyle.money(ctrl.savedTotal),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ComplaintStyle.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in ctrl.savedExpenses) _savedTile(ctrl, e),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: ctrl.isSubmitting ? null : () => _submitSaved(ctrl),
              icon: ctrl.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Submit all as one claim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ComplaintStyle.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ComplaintStyle.navy.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedTile(ExpenseClaimController ctrl, SavedExpense e) {
    final first = e.lines.isEmpty ? null : e.lines.first;
    final title = first == null
        ? 'Expense'
        : e.lines.length == 1
        ? first.expenseType
        : '${first.expenseType} +${e.lines.length - 1} more';
    final date = DateTime.tryParse(first?.expenseDate ?? '');
    final details = [
      ComplaintStyle.formatDate(date ?? e.savedAt),
      if (first?.description != null) first!.description!,
      if (e.receiptPaths.isNotEmpty)
        '${e.receiptPaths.length} receipt${e.receiptPaths.length == 1 ? '' : 's'}',
    ].join('  •  ');

    return InkWell(
      onTap: ctrl.isSubmitting ? null : () => _openCreate(e),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              ExpenseStyle.typeIcon(first?.expenseType ?? ''),
              size: 20,
              color: ComplaintStyle.navy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ComplaintStyle.navy,
                    ),
                  ),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ComplaintStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              ExpenseStyle.money(e.total),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ComplaintStyle.navy,
              ),
            ),
            IconButton(
              onPressed: ctrl.isSubmitting
                  ? null
                  : () => _confirmRemoveSaved(ctrl, e),
              visualDensity: VisualDensity.compact,
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: ExpenseStyle.rejected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a tile filters the list by that approval status.
  Widget _summaryTile(
    ExpenseClaimController ctrl,
    String label,
    String filter,
    double? amount,
    Color dot,
  ) {
    final selected = ctrl.statusFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setStatusFilter(selected ? null : filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(selected ? 0.22 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.white70 : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount == null ? '—' : ExpenseStyle.moneyShort(amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(ExpenseClaimController ctrl) {
    if (ctrl.isLoading && ctrl.claims.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(
            child: CircularProgressIndicator(color: ComplaintStyle.navy),
          ),
        ),
      ];
    }

    if (ctrl.error != null && ctrl.claims.isEmpty) {
      return [
        _message(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load claims',
          subtitle: ctrl.error!,
          action: OutlinedButton.icon(
            onPressed: ctrl.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style:
                OutlinedButton.styleFrom(foregroundColor: ComplaintStyle.navy),
          ),
        ),
      ];
    }

    if (ctrl.claims.isEmpty) {
      return [
        _message(
          icon: Icons.receipt_long_outlined,
          title: ctrl.statusFilter == null ? 'No claims yet' : 'Nothing here',
          subtitle: ctrl.statusFilter == null
              ? 'Tap "New Claim" to claim an expense.'
              : 'No ${expenseStatusLabel(ctrl.statusFilter!).toLowerCase()} claims.',
        ),
      ];
    }

    return [
      for (final c in ctrl.claims) ...[
        _ExpenseClaimCard(claim: c),
        const SizedBox(height: 12),
      ],
      if (ctrl.isLoadingMore)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ComplaintStyle.navy,
            ),
          ),
        ),
    ];
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ComplaintStyle.navy.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: ComplaintStyle.navy),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ComplaintStyle.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: ComplaintStyle.muted),
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }
}

class _ExpenseClaimCard extends StatelessWidget {
  final ExpenseClaim claim;

  const _ExpenseClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final c = claim;
    final label = c.statusLabel;
    final color = ExpenseStyle.statusColor(label);
    final sanctionedDiffers = c.approvalStatus == 'Approved' &&
        c.totalSanctionedAmount != c.totalClaimedAmount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseClaimDetailsPage(claimName: c.name),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: ComplaintStyle.card(),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ExpenseStyle.money(c.totalClaimedAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ComplaintStyle.navy,
                      ),
                    ),
                    if (sanctionedDiffers)
                      Text(
                        'Sanctioned ${ExpenseStyle.money(c.totalSanctionedAmount)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ExpenseStyle.approved,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ComplaintStyle.muted,
                            ),
                          ),
                        ),
                        const Text(
                          '  •  ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: ComplaintStyle.muted,
                          ),
                        ),
                        Text(
                          ComplaintStyle.formatDate(c.postingDate),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: ComplaintStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ComplaintPill(
                label: label,
                color: color,
                icon: ExpenseStyle.statusIcon(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
