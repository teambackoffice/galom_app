import 'package:flutter/material.dart';

void main() => runApp(const LeaveApprovalApp());

// ── Palette ─────────────────────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F1E1C);
  static const inkMuted = Color(0xFF7A7870);
  static const line = Color(0xFFE9E6DE);

  static const indigo = Color(0xFF3D3AA8);
  static const indigoSoft = Color(0xFFEDECF9);

  static const amber = Color(0xFFB8740C);
  static const amberSoft = Color(0xFFFBF0DD);

  static const green = Color(0xFF2F7D32);
  static const greenSoft = Color(0xFFE7F4E4);

  static const red = Color(0xFFB23B2E);
  static const redSoft = Color(0xFFFBEAE6);
}

class LeaveApprovalApp extends StatelessWidget {
  const LeaveApprovalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave approvals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          surface: AppColors.bg,
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Roboto')),
      ),
      home: const LeaveListScreen(),
    );
  }
}

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  final String id;
  final String name;
  final String role;
  final String initials;
  final String type;
  final String from;
  final String to;
  final int days;
  final String applied;
  final String reason;
  final int balance;
  LeaveStatus status;

  LeaveRequest({
    required this.id,
    required this.name,
    required this.role,
    required this.initials,
    required this.type,
    required this.from,
    required this.to,
    required this.days,
    required this.applied,
    required this.reason,
    required this.balance,
    this.status = LeaveStatus.pending,
  });
}

final List<LeaveRequest> demoLeaves = [
  LeaveRequest(
    id: '1',
    name: 'Priya Nair',
    role: 'Product Designer',
    initials: 'PN',
    type: 'Annual leave',
    from: 'Jul 14, 2026',
    to: 'Jul 18, 2026',
    days: 5,
    applied: 'Jun 28, 2026',
    reason: "Family trip to Munnar planned for the kids' summer break.",
    balance: 12,
  ),
  LeaveRequest(
    id: '2',
    name: 'Arjun Menon',
    role: 'Backend Engineer',
    initials: 'AM',
    type: 'Sick leave',
    from: 'Jul 1, 2026',
    to: 'Jul 2, 2026',
    days: 2,
    applied: 'Jun 30, 2026',
    reason: 'Fever and viral infection, doctor advised rest for 2 days.',
    balance: 6,
  ),
  LeaveRequest(
    id: '3',
    name: 'Sara Thomas',
    role: 'QA Analyst',
    initials: 'ST',
    type: 'Casual leave',
    from: 'Jul 10, 2026',
    to: 'Jul 10, 2026',
    days: 1,
    applied: 'Jun 27, 2026',
    reason: "Attending a relative's wedding ceremony.",
    balance: 4,
  ),
  LeaveRequest(
    id: '4',
    name: 'Kiran Das',
    role: 'DevOps Engineer',
    initials: 'KD',
    type: 'Annual leave',
    from: 'Aug 3, 2026',
    to: 'Aug 7, 2026',
    days: 5,
    applied: 'Jun 25, 2026',
    reason: 'Pre-planned vacation, travel tickets already booked.',
    balance: 9,
  ),
  LeaveRequest(
    id: '5',
    name: 'Lakshmi Pillai',
    role: 'HR Associate',
    initials: 'LP',
    type: 'Sick leave',
    from: 'Jun 29, 2026',
    to: 'Jun 30, 2026',
    days: 2,
    applied: 'Jun 29, 2026',
    reason: 'Recovering from minor surgery, needs short rest period.',
    balance: 5,
  ),
];

// ── Status styling helper ──────────────────────────────────────────────
class _StatusStyle {
  final Color fg;
  final Color bg;
  final String label;
  final IconData icon;
  const _StatusStyle(this.fg, this.bg, this.label, this.icon);
}

_StatusStyle statusStyle(LeaveStatus s) {
  switch (s) {
    case LeaveStatus.approved:
      return const _StatusStyle(
        AppColors.green,
        AppColors.greenSoft,
        'Approved',
        Icons.check_circle_rounded,
      );
    case LeaveStatus.rejected:
      return const _StatusStyle(
        AppColors.red,
        AppColors.redSoft,
        'Rejected',
        Icons.cancel_rounded,
      );
    case LeaveStatus.pending:
      return const _StatusStyle(
        AppColors.amber,
        AppColors.amberSoft,
        'Pending',
        Icons.schedule_rounded,
      );
  }
}

const _avatarPalette = [
  [Color(0xFFEDECF9), Color(0xFF3D3AA8)],
  [Color(0xFFFBF0DD), Color(0xFFB8740C)],
  [Color(0xFFFBEAE6), Color(0xFFB23B2E)],
  [Color(0xFFE7F4E4), Color(0xFF2F7D32)],
  [Color(0xFFFCEAF0), Color(0xFF993556)],
];

List<Color> avatarColors(String seed) =>
    _avatarPalette[seed.codeUnitAt(0) % _avatarPalette.length];

// ── List screen ─────────────────────────────────────────────────────────
class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  final List<LeaveRequest> leaves = demoLeaves;
  LeaveStatus? filter; // null = all

  int countOf(LeaveStatus s) => leaves.where((l) => l.status == s).length;

  List<LeaveRequest> get visible => leaves.where((l) {
    final matchesFilter = filter == null || l.status == filter;
    final q = _searchQuery.toLowerCase();
    final matchesSearch =
        q.isEmpty ||
        l.name.toLowerCase().contains(q) ||
        l.type.toLowerCase().contains(q);
    return matchesFilter && matchesSearch;
  }).toList();

  Future<void> _openDetail(LeaveRequest leave) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: LeaveDetailScreen(leave: leave),
        ),
      ),
    );
    setState(() {});
  }

  bool _isSearchExpanded = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ─────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF764BA2).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Leave approvals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        // Search toggle
                        IconButton(
                          onPressed: () => setState(() {
                            _isSearchExpanded = !_isSearchExpanded;
                            if (!_isSearchExpanded) _searchQuery = '';
                          }),
                          icon: Icon(
                            _isSearchExpanded
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: Colors.black,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    // ── Search box ──────────────────────────────────
                    if (_isSearchExpanded) ...[
                      const SizedBox(height: 14),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search by name or leave type…',
                          hintStyle: const TextStyle(
                            color: AppColors.inkMuted,
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.inkMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.indigo,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: filter == null,
                      onTap: () => setState(() => filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending',
                      selected: filter == LeaveStatus.pending,
                      onTap: () => setState(() => filter = LeaveStatus.pending),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Approved',
                      selected: filter == LeaveStatus.approved,
                      onTap: () =>
                          setState(() => filter = LeaveStatus.approved),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Rejected',
                      selected: filter == LeaveStatus.rejected,
                      onTap: () =>
                          setState(() => filter = LeaveStatus.rejected),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: visible.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'Nothing here.',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final leave = visible[index];
                        return _LeaveCard(
                          leave: leave,
                          onTap: () => _openDetail(leave),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.85),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback onTap;
  const _LeaveCard({required this.leave, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(leave.status);
    final colors = avatarColors(leave.id);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors[0],
                child: Text(
                  leave.initials,
                  style: TextStyle(
                    color: colors[1],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${leave.type} · ${leave.days} day${leave.days > 1 ? 's' : ''} · ${leave.from}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 13, color: style.fg),
                    const SizedBox(width: 4),
                    Text(
                      style.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: style.fg,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail screen ──────────────────────────────────────────────────────
class LeaveDetailScreen extends StatefulWidget {
  final LeaveRequest leave;
  const LeaveDetailScreen({super.key, required this.leave});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late LeaveRequest leave;

  @override
  void initState() {
    super.initState();
    leave = widget.leave;
  }

  Future<void> _setStatus(LeaveStatus status) async {
    final isApproved = status == LeaveStatus.approved;

    // ── Confirmation dialog ──────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.greenSoft : AppColors.redSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isApproved ? AppColors.green : AppColors.red,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                isApproved ? 'Approve leave?' : 'Reject leave?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              // Body
              Text(
                isApproved
                    ? 'You are about to approve the leave request from ${leave.name}. This action will notify the employee.'
                    : 'You are about to reject the leave request from ${leave.name}. This action will notify the employee.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.inkMuted,
                  fontFamily: 'Roboto',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkMuted,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isApproved
                            ? AppColors.green
                            : AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        isApproved ? 'Yes, approve' : 'Yes, reject',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Apply status & show success sheet ────────────────────────────
    setState(() => leave.status = status);

    final successStyle = isApproved
        ? _StatusStyle(
            AppColors.green,
            AppColors.greenSoft,
            'Approved',
            Icons.check_circle_rounded,
          )
        : _StatusStyle(
            AppColors.red,
            AppColors.redSoft,
            'Rejected',
            Icons.cancel_rounded,
          );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        });
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: successStyle.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  successStyle.icon,
                  color: successStyle.fg,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isApproved ? 'Request approved!' : 'Request rejected',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      leave.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.inkMuted),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.inkMuted,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(leave.status);
    final colors = avatarColors(leave.id);
    final isPending = leave.status == LeaveStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6E)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF764BA2).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_ind_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Request details',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors[0],
                  child: Text(
                    leave.initials,
                    style: TextStyle(
                      color: colors[1],
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        leave.role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.fg),
                      const SizedBox(width: 5),
                      Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: style.fg,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _infoTile(Icons.beach_access_rounded, 'Leave type', leave.type),
                const SizedBox(width: 10),
                _infoTile(
                  Icons.event_rounded,
                  'Duration',
                  '${leave.days} day${leave.days > 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoTile(
                  Icons.donut_small_rounded,
                  'Balance',
                  '${leave.balance} days left',
                ),
                const SizedBox(width: 10),
                _infoTile(Icons.history_rounded, 'Applied on', leave.applied),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _dateRow('From', leave.from),
                  const Divider(height: 1, color: AppColors.line),
                  _dateRow('To', leave.to),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.inkMuted,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                leave.reason,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.ink,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: isPending
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(
                          color: AppColors.red,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _setStatus(LeaveStatus.rejected),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _setStatus(LeaveStatus.approved),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Approve',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _dateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontFamily: 'Roboto',
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
