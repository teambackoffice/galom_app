import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_leave_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_leave_modal.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/state_views.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Switches to the Leaves tab (one tap from anywhere in the shell).
void openLeaveRequests(BuildContext context) {
  context.read<ManagerLeaveController>().setFilter(LeaveFilter.managerApproval);
  context.read<ManagerNavController>().goTo(ManagerTab.leaves);
}

class ManagerLeavesScreen extends StatefulWidget {
  const ManagerLeavesScreen({super.key});

  @override
  State<ManagerLeavesScreen> createState() => _ManagerLeavesScreenState();
}

class _ManagerLeavesScreenState extends State<ManagerLeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ManagerLeaveController>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ManagerLeaveController>();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManagerTabHeader(
            title: 'Leave requests',
            subtitle: c.managerApprovalCount > 0
                ? '${c.managerApprovalCount} waiting for your approval'
                : 'Approve or reject team leave',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MSpace.lg),
            child: TextField(
              onChanged: c.setSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search employee or leave type',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: MColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: MSpace.lg,
                vertical: MSpace.sm,
              ),
              children: [
                for (final f in LeaveFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: MSpace.sm),
                    child: _FilterChip(
                      label: c.hasLoaded && f != LeaveFilter.all
                          ? '${f.label} ${c.count(f)}'
                          : f.label,
                      selected: c.filter == f,
                      onTap: () => c.setFilter(f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: MColors.accent,
              onRefresh: c.load,
              child: _body(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(ManagerLeaveController c) {
    Widget centered(Widget child) => LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: child),
        ),
      ),
    );

    if (c.isLoading && !c.hasLoaded) {
      return const ManagerSkeletonList(
        count: 5,
        padding: EdgeInsets.fromLTRB(MSpace.lg, 0, MSpace.lg, MSpace.lg),
      );
    }
    if (c.error != null && !c.hasLoaded) {
      return centered(ManagerErrorState(error: c.error!, onRetry: c.load));
    }
    final list = c.visible;
    if (list.isEmpty) {
      return centered(
        ManagerEmptyState(
          icon: Icons.beach_access_outlined,
          title: c.search.isNotEmpty
              ? 'No leave requests found'
              : switch (c.filter) {
                  LeaveFilter.pending => 'No pending leave requests',
                  LeaveFilter.managerApproval =>
                    'No leaves awaiting manager approval',
                  _ => 'No leave requests found',
                },
          filtered: c.search.isNotEmpty,
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(MSpace.lg, 0, MSpace.lg, MSpace.xxl),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: MSpace.md),
      itemBuilder: (context, i) => LeaveCard(
        leave: list[i],
        onTap: () => showLeaveDetail(context, list[i].name),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? MColors.navy : MColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? MColors.navy : MColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : MColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String leaveDates(LeaveApplication l) {
  final from = l.fromDate, to = l.toDate;
  if (from == null) return '—';
  if (to == null || DateUtils.isSameDay(from, to)) return MFormat.date(from);
  return MFormat.range(from, to);
}

String leaveDays(LeaveApplication l) {
  final d = l.totalLeaveDays;
  final text = d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
  return '$text day${d == 1 ? '' : 's'}${l.halfDay ? ' (half day)' : ''}';
}

class LeaveCard extends StatelessWidget {
  const LeaveCard({super.key, required this.leave, this.onTap});

  final LeaveApplication leave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = leave;
    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ManagerAvatar(name: l.displayName, size: 38),
              const SizedBox(width: MSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MText.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.leaveType}  ·  ${leaveDays(l)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MText.meta,
                    ),
                    const SizedBox(height: 4),
                    StatusChip(l.displayStatus, dense: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MSpace.sm),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 15,
                color: MColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  leaveDates(l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.meta.copyWith(
                    color: MColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (l.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              l.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MText.meta,
            ),
          ],
          if (l.canAct) ...[
            const SizedBox(height: MSpace.md),
            LeaveActions(leave: l),
          ],
        ],
      ),
    );
  }
}

/// Approve / Reject buttons with confirmation and progress.
class LeaveActions extends StatelessWidget {
  const LeaveActions({super.key, required this.leave, this.onDone});

  final LeaveApplication leave;
  final VoidCallback? onDone;

  Future<void> _run(BuildContext context, bool approve) async {
    final c = context.read<ManagerLeaveController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _LeaveDecisionDialog(leave: leave, approve: approve),
    );
    if (ok != true) return;
    final error = approve ? await c.approve(leave) : await c.reject(leave);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? (approve ? 'Leave approved' : 'Leave rejected')),
        backgroundColor: error != null ? MColors.red : null,
      ),
    );
    if (error == null) onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<ManagerLeaveController, bool>(
      (c) => c.isBusy(leave.name),
    );
    if (busy) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _run(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: MColors.red,
              side: const BorderSide(color: MColors.border),
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MSpace.radiusSm),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: MSpace.sm),
        Expanded(
          child: FilledButton(
            onPressed: () => _run(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: MColors.green,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MSpace.radiusSm),
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirmation for approve / reject: icon badge, leave summary, and
/// full-width actions sized for small phones.
class _LeaveDecisionDialog extends StatelessWidget {
  const _LeaveDecisionDialog({required this.leave, required this.approve});

  final LeaveApplication leave;
  final bool approve;

  @override
  Widget build(BuildContext context) {
    final color = approve ? MColors.green : MColors.red;
    final bg = approve ? MColors.greenBg : MColors.redBg;
    return Dialog(
      backgroundColor: MColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: MSpace.xxl,
        vertical: MSpace.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MSpace.radius + 4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MSpace.xl,
            MSpace.xxl,
            MSpace.xl,
            MSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(
                  approve ? Icons.check_rounded : Icons.close_rounded,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: MSpace.lg),
              Text(
                approve ? 'Approve leave?' : 'Reject leave?',
                textAlign: TextAlign.center,
                style: MText.section.copyWith(fontSize: 18),
              ),
              const SizedBox(height: MSpace.xs),
              Text(
                approve
                    ? 'This leave will be approved and deducted from the balance.'
                    : 'This request will be closed and cannot be undone.',
                textAlign: TextAlign.center,
                style: MText.meta,
              ),
              const SizedBox(height: MSpace.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MSpace.md),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(MSpace.radiusSm),
                  border: Border.all(color: MColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ManagerAvatar(name: leave.displayName, size: 36),
                        const SizedBox(width: MSpace.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MText.cardTitle,
                              ),
                              Text(
                                leave.leaveType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MText.meta,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: MSpace.sm + 2),
                      child: Divider(height: 1, color: MColors.divider),
                    ),
                    _DialogInfoRow(
                      icon: Icons.event_outlined,
                      text: leaveDates(leave),
                    ),
                    const SizedBox(height: 6),
                    _DialogInfoRow(
                      icon: Icons.timelapse_rounded,
                      text: leaveDays(leave),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSpace.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MSpace.radiusSm),
                    ),
                  ),
                  icon: Icon(
                    approve ? Icons.check_rounded : Icons.close_rounded,
                    size: 20,
                  ),
                  label: Text(
                    approve ? 'Approve' : 'Reject',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: MSpace.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: MColors.textSecondary,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MColors.textMuted),
        const SizedBox(width: MSpace.sm),
        Expanded(
          child: Text(
            text,
            style: MText.meta.copyWith(
              color: MColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full leave details in a bottom sheet (reads live state by name so the
/// status updates after approve/reject).
Future<void> showLeaveDetail(BuildContext context, String name) {
  final controller = context.read<ManagerLeaveController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: _LeaveDetailSheet(name: name),
    ),
  );
}

class _LeaveDetailSheet extends StatelessWidget {
  const _LeaveDetailSheet({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.watch<ManagerLeaveController>().byName(name);
    if (l == null) return const SizedBox(height: 120);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MSpace.xl,
            0,
            MSpace.xl,
            MSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ManagerAvatar(name: l.displayName, size: 44),
                  const SizedBox(width: MSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.displayName,
                          style: MText.section.copyWith(fontSize: 17),
                        ),
                        Text(l.employee, style: MText.meta),
                        const SizedBox(height: 6),
                        StatusChip(l.displayStatus),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpace.lg),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MColors.background,
                  borderRadius: BorderRadius.circular(MSpace.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.leaveType, style: MText.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${leaveDates(l)}  ·  ${leaveDays(l)}',
                      style: MText.meta.copyWith(color: MColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSpace.md),
              if (l.reason != null) ...[
                const Text('REASON', style: MText.label),
                const SizedBox(height: 4),
                Text(l.reason!, style: MText.body),
                const SizedBox(height: MSpace.md),
              ],
              if (l.halfDay && l.halfDayDate != null)
                InfoRow('Half day on', MFormat.date(l.halfDayDate)),
              if (l.leaveBalance != null)
                InfoRow(
                  'Balance before leave',
                  '${MFormat.qty(l.leaveBalance!)} days',
                ),
              if (l.department != null) InfoRow('Department', l.department!),
              if (l.leaveApproverName != null)
                InfoRow('Leave approver', l.leaveApproverName!),
              if (l.postingDate != null)
                InfoRow('Applied on', MFormat.date(l.postingDate)),
              InfoRow('Application', l.name, copyable: true),
              if (l.canAct) ...[
                const SizedBox(height: MSpace.lg),
                LeaveActions(
                  leave: l,
                  onDone: () => Navigator.of(context).maybePop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
