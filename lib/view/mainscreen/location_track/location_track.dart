// lib/view/mainscreen/location_track/location_tracking_page.dart

import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/attendance_check_controller.dart';
import 'package:provider/provider.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/customer_visit_log.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/customer_visit_timer.dart';

// Employee ID is read from secure storage by AttendanceService directly.

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage>
    with TickerProviderStateMixin {
  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse for status dot
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Entrance slide + fade
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Bootstrap: fetch real status from the server.
    // employee_id is read from secure storage by AttendanceService.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatedAttendanceController>().init();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Formatters ───────────────────────────────────────────────────────────────
  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _formatDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) return '0h 00m';
    final end = checkOut ?? DateTime.now();
    final diff = end.difference(checkIn);
    return '${diff.inHours}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}m';
  }

  String _formatDate() {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
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
    final n = DateTime.now();
    return '${wd[n.weekday - 1]}, ${mo[n.month - 1]} ${n.day}';
  }

  // ── Confirm Dialog ───────────────────────────────────────────────────────────
  void _confirm({
    required String title,
    required String message,
    required String label,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1B3E),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Color(0xFF636E72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF636E72)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<UpdatedAttendanceController>(
      builder: (context, ctrl, _) {
        final isIn = ctrl.isTracking;

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F8),
          body: SafeArea(
            child: ctrl.isInitializing
                ? _buildShimmer()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(ctrl),
                            const SizedBox(height: 8),
                            _buildStatusBadge(ctrl),
                            const SizedBox(height: 20),
                            _buildMainCard(ctrl, isIn),
                            const SizedBox(height: 16),
                            _buildLogCard(ctrl),
                            if (ctrl.hasPendingEntries) ...[
                              const SizedBox(height: 16),
                              _buildPendingBanner(ctrl),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(UpdatedAttendanceController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        children: [
          // Avatar / icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B3E), Color(0xFF1E3A7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D1B3E).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B3E),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _formatDate(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),
          // Menu
          _menuButton(),
        ],
      ),
    );
  }

  Widget _menuButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.more_horiz, color: Color(0xFF0D1B3E), size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: Colors.white,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'visit_log',
          child: Row(
            children: [
              Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF0D1B3E)),
              SizedBox(width: 10),
              Text(
                'Customer Visit Log',
                style: TextStyle(fontSize: 14, color: Color(0xFF0D1B3E)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'customer_timer',
          child: Row(
            children: [
              Icon(Icons.timer_rounded, size: 18, color: Color(0xFF1E88E5)),
              SizedBox(width: 10),
              Text(
                'Customer Visit Timer',
                style: TextStyle(fontSize: 14, color: Color(0xFF0D1B3E)),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'visit_log') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomerVisitLogger()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomerVisitTimerPage()),
          );
        }
      },
    );
  }

  // ── Status Badge ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatusBadge(UpdatedAttendanceController ctrl) {
    final isIn = ctrl.isTracking;
    final isOut = !isIn && ctrl.checkOutTime != null;

    final Color color;
    final Color bg;
    final String label;

    if (isIn) {
      color = const Color(0xFF00875A);
      bg = const Color(0xFFE3FCF7);
      label = 'Currently Checked In';
    } else if (isOut) {
      color = const Color(0xFFF57F17);
      bg = const Color(0xFFFFF8E1);
      label = 'Checked Out';
    } else {
      color = const Color(0xFFB71C1C);
      bg = const Color(0xFFFCE4EC);
      label = 'Not Checked In';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Opacity(
                  opacity: isIn ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Main Card ────────────────────────────────────────────────────────────────
  Widget _buildMainCard(UpdatedAttendanceController ctrl, bool isIn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top decorative band ─────────────────────────────────────────
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isIn
                    ? [const Color(0xFF00875A), const Color(0xFF57D9A3)]
                    : [const Color(0xFFB71C1C), const Color(0xFFEF5350)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                // ── Time cells ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _TimeCell(
                        label: 'CHECK IN',
                        value: _formatTime(ctrl.checkInTime),
                        active: ctrl.checkInTime != null,
                        activeColor: const Color(0xFF00875A),
                        icon: Icons.login_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeCell(
                        label: 'CHECK OUT',
                        value: _formatTime(ctrl.checkOutTime),
                        active: ctrl.checkOutTime != null,
                        activeColor: const Color(0xFFB71C1C),
                        icon: Icons.logout_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Duration bar ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timelapse_rounded,
                        size: 18,
                        color: Color(0xFF0D1B3E),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF636E72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (_, __) => Text(
                          _formatDuration(ctrl.checkInTime, ctrl.checkOutTime),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Action button ────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading
                        ? null
                        : () {
                            if (isIn) {
                              _confirm(
                                title: 'Check Out?',
                                message:
                                    'Are you sure you want to check out now?',
                                label: 'Yes, Check Out',
                                color: const Color(0xFFB71C1C),
                                onConfirm: ctrl.stopTracking,
                              );
                            } else {
                              _confirm(
                                title: 'Check In?',
                                message:
                                    'Are you sure you want to check in now?',
                                label: 'Yes, Check In',
                                color: const Color(0xFF00875A),
                                onConfirm: ctrl.startTracking,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIn
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFF00875A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: ctrl.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isIn
                                    ? Icons.logout_rounded
                                    : Icons.login_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isIn ? 'Check Out' : 'Check In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // ── Error message ────────────────────────────────────
                if (ctrl.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: ctrl.error!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Log Card ─────────────────────────────────────────────────────────
  Widget _buildLogCard(UpdatedAttendanceController ctrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withOpacity(0.06),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: Color(0xFF0D1B3E),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "TODAY'S LOG",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF0D1B3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ctrl.checkInTime == null && ctrl.checkOutTime == null)
            const _EmptyLog()
          else ...[
            if (ctrl.checkInTime != null)
              _LogRow(
                dot: const Color(0xFF00875A),
                label: 'Checked in',
                value: _formatTime(ctrl.checkInTime),
              ),
            if (ctrl.checkOutTime != null) ...[
              if (ctrl.checkInTime != null) const _LogDivider(),
              _LogRow(
                dot: const Color(0xFFB71C1C),
                label: 'Checked out',
                value: _formatTime(ctrl.checkOutTime),
              ),
            ],
            if (ctrl.checkInTime != null && ctrl.checkOutTime != null) ...[
              const _LogDivider(),
              _LogRow(
                dot: const Color(0xFF0D1B3E),
                label: 'Total duration',
                value: _formatDuration(ctrl.checkInTime, ctrl.checkOutTime),
                bold: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Pending Banner ───────────────────────────────────────────────────────────
  Widget _buildPendingBanner(UpdatedAttendanceController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 18,
            color: Color(0xFFF57F17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${ctrl.pendingEntriesCount} entries pending upload',
              style: const TextStyle(fontSize: 13, color: Color(0xFFF57F17)),
            ),
          ),
          GestureDetector(
            onTap: ctrl.sendPendingEntries,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading ──────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 180, height: 22, radius: 8),
          const SizedBox(height: 8),
          _ShimmerBox(width: 120, height: 14, radius: 6),
          const SizedBox(height: 28),
          _ShimmerBox(width: double.infinity, height: 220, radius: 24),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 140, radius: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TimeCell extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color activeColor;
  final IconData icon;

  const _TimeCell({
    required this.label,
    required this.value,
    required this.active,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.06) : const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? activeColor.withOpacity(0.2) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? activeColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: active ? activeColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: active ? activeColor : Colors.grey.shade300,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  final bool bold;

  const _LogRow({
    required this.dot,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF2D3436),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: bold ? const Color(0xFF0D1B3E) : const Color(0xFF636E72),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LogDivider extends StatelessWidget {
  const _LogDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          'No activity recorded yet.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFB71C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
