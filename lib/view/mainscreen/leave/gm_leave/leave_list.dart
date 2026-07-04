import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/admin_get_leaves_controller.dart';
import 'package:location_tracker_app/modal/admin_leaves_modal.dart';
import 'package:location_tracker_app/service/admin_get_leave_service.dart';
import 'package:location_tracker_app/view/mainscreen/leave/gm_leave/leave_details.dart';
import 'package:provider/provider.dart';
import 'package:location_tracker_app/controller/create_leave_controller.dart';
import 'package:location_tracker_app/controller/leave_application_controller.dart';
import 'package:location_tracker_app/view/mainscreen/leave/leave_application.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
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

// ── UI model (unchanged) ──────────────────────────────────────────────────────
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
  String rawStatus;

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
    required this.rawStatus,
  });
}

// ── Mapping helpers ───────────────────────────────────────────────────────────

/// "Open" → pending, "Approved" → approved, "Rejected" → rejected
LeaveStatus _mapStatus(String apiStatus) {
  switch (apiStatus.toLowerCase()) {
    case 'approved':
      return LeaveStatus.approved;
    case 'rejected':
      return LeaveStatus.rejected;
    default: // "Open" or anything else
      return LeaveStatus.pending;
  }
}

/// Returns the reverse string suitable for the API call (used when
/// approving / rejecting through the backend).

/// Derives two-letter initials from a full name, e.g. "Priya Nair" → "PN".
String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Formats a raw API date string ("2026-07-14") to a readable label
/// ("Jul 14, 2026"). Falls back to the raw value if parsing fails.
String _fmtDate(String raw) {
  try {
    final d = DateTime.parse(raw);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  } catch (_) {
    return raw;
  }
}

/// Converts the API model to the UI model.
LeaveRequest _toLeaveRequest(AdminLeaveApplicationModalClass a) {
  return LeaveRequest(
    id: a.name, // doc-name as unique id
    name: a.employeeName,
    role: a.department ?? 'Employee', // department as role label
    initials: _initials(a.employeeName),
    type: a.leaveType,
    from: _fmtDate(a.fromDate),
    to: _fmtDate(a.toDate),
    days: a.totalLeaveDays.toInt(),
    applied: _fmtDate(a.postingDate),
    reason: a.description ?? 'No reason provided.',
    balance: a.leaveBalance.toInt(),
    status: _mapStatus(a.status),
    rawStatus: a.status,
  );
}

// ── Status styling helper ─────────────────────────────────────────────────────
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

// ── List screen ───────────────────────────────────────────────────────────────
class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  // ── Controller ──────────────────────────────────────────────────────────────
  final GetAdminLeaveApplicationController _controller =
      GetAdminLeaveApplicationController();

  // Local mutable copies so approve / reject updates are reflected immediately
  // without a full re-fetch.
  List<LeaveRequest> _leaves = [];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.fetchLeaveApplications();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {
      if (!_controller.isLoading) {
        if (_controller.leaveApplications.isEmpty) {
          _leaves = [];
          _errorMessage = 'No leave applications found.';
        } else {
          _errorMessage = null;
          _leaves = _controller.leaveApplications.map(_toLeaveRequest).toList();
        }
      }
    });
  }

  LeaveStatus? _filter;
  bool _isSearchExpanded = false;
  String _searchQuery = '';

  List<LeaveRequest> get _visible => _leaves.where((l) {
    final matchesFilter = _filter == null || l.status == _filter;
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
    setState(() {}); // reflect any status change made on the detail screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        // Refresh button
                        if (!_controller.isLoading)
                          IconButton(
                            onPressed: _refreshData,
                            icon: const Icon(
                              Icons.refresh_rounded,
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
                      ],
                    ),
                    // ── Search box ───────────────────────────────────────────
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



            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => CreateLeaveApplicationController(),
                ),
                ChangeNotifierProvider(
                  create: (_) => GetLeaveApplicationController(),
                ),
              ],
              child: const LeaveApplySheet(),
            ),
          );
        },
        backgroundColor: AppColors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_controller.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
      );
    }

    // Error / empty state
    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_rounded,
                size: 48,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _visible;

    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: Text(
              'Nothing here.',
              style: TextStyle(color: AppColors.inkMuted, fontFamily: 'Roboto'),
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final leave = items[index];
        return _LeaveCard(leave: leave, onTap: () => _openDetail(leave));
      },
    );
  }

  /// Clears the local list first so the controller update rebuilds it fresh.
  void _refreshData() {
    setState(() {
      _leaves = [];
      _errorMessage = null;
    });
    _controller.fetchLeaveApplications();
  }
}



// ── Leave card ────────────────────────────────────────────────────────────────
class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback onTap;
  const _LeaveCard({required this.leave, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(leave.status);
    final colors = avatarColors(leave.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.line.withOpacity(0.6), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: style.fg, width: 4)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Modern Squircle/Rounded Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors[0],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            leave.initials,
                            style: TextStyle(
                              color: colors[1],
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Name and Role/Type (with full horizontal space)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.name.isNotEmpty
                                    ? leave.name[0].toUpperCase() +
                                          leave.name.substring(1)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                leave.role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.line),
                    const SizedBox(height: 12),
                    // Details row: Type, Duration, From date, and Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Leave Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      leave.type,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Text(
                                    leave.from,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right: Premium Pill Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(style.icon, size: 12, color: style.fg),
                              const SizedBox(width: 4),
                              Text(
                                leave.rawStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: style.fg,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail screen ─────────────────────────────────────────────────────────────
