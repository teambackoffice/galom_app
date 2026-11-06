import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/customer_log_visit_controller.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/customer_visit_log.dart';
import 'package:provider/provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

MaterialColor _counterColor(bool isFirst) =>
    isFirst ? Colors.green : Colors.orange;

IconData _counterIcon(bool isFirst) =>
    isFirst ? Icons.wb_sunny_outlined : Icons.flag_outlined;

String _clock(DateTime? t) =>
    t == null ? '--:--' : DateFormat('h:mm a').format(t);

String _shortDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${d.inMinutes} min';
}

String _stopwatch(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Rebuilds its child every second, for live timers.
class _Ticker extends StatefulWidget {
  const _Ticker({required this.builder});
  final WidgetBuilder builder;

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Open meeting (on the Field Visit Logger) ─────────────────────────────────

/// Shown while a first/last counter visit is checked in but not checked out.
/// Collects the meeting remark and records the check-out. Once checked out,
/// the card disappears.
class OpenMeetingCard extends StatefulWidget {
  const OpenMeetingCard({super.key, required this.visit});

  final OpenCounterVisit visit;

  @override
  State<OpenMeetingCard> createState() => _OpenMeetingCardState();
}

class _OpenMeetingCardState extends State<OpenMeetingCard> {
  final TextEditingController _remarks = TextEditingController();
  final FocusNode _focus = FocusNode();

  static const _quickRemarks = [
    'Order confirmed',
    'Follow-up needed',
    'No order today',
    'Payment collected',
    'Stock checked',
  ];

  @override
  void initState() {
    super.initState();
    _remarks.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _remarks.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _addQuickRemark(String text) {
    final current = _remarks.text.trimRight();
    final next = current.isEmpty
        ? text
        : current.endsWith('.') || current.endsWith(',')
        ? '$current $text'
        : '$current, $text';
    _remarks.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _confirmAndFinish() async {
    final remarks = _remarks.text.trim();
    if (remarks.isEmpty) return;
    FocusScope.of(context).unfocus();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _ConfirmCheckoutSheet(visit: widget.visit, remarks: remarks),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context
        .read<LogCustomerVisitController>()
        .finishMeeting(remarks);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(error ?? 'Meeting completed and checked out'),
        backgroundColor: error == null ? Colors.green[700] : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final busy = context.watch<LogCustomerVisitController>().isFinishingMeeting;
    final color = _counterColor(v.isFirstCounter);
    final start = v.checkinAt;
    final canFinish = !busy && _remarks.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color[600]!, color[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _counterIcon(v.isFirstCounter),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _PulsingDot(color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '${v.counterLabel.toUpperCase()} · IN MEETING',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        v.customerName.isNotEmpty ? v.customerName : v.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Time strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    icon: Icons.login_rounded,
                    label: 'Checked in',
                    value: _clock(start),
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Ticker(
                    builder: (_) => _TimeTile(
                      icon: Icons.timer_outlined,
                      label: 'In meeting',
                      value: start == null
                          ? '--:--'
                          : _stopwatch(DateTime.now().difference(start)),
                      color: color,
                      monospace: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remarks
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meeting remarks *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarks,
                  focusNode: _focus,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'What happened in the meeting?',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color[600]!, width: 1.6),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final q in _quickRemarks)
                      ActionChip(
                        label: Text(q),
                        onPressed: busy ? null : () => _addQuickRemark(q),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          color: color[800],
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: color[50],
                        side: BorderSide(color: color[100]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canFinish ? _confirmAndFinish : null,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.task_alt_rounded, size: 20),
                    label: Text(
                      busy ? 'Saving...' : 'End Meeting & Check Out',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color[700],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        canFinish || busy
                            ? 'Check-out time is recorded when you tap the button'
                            : 'Add a remark to end the meeting',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color[700]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color[900],
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmCheckoutSheet extends StatelessWidget {
  const _ConfirmCheckoutSheet({required this.visit, required this.remarks});

  final OpenCounterVisit visit;
  final String remarks;

  @override
  Widget build(BuildContext context) {
    final color = _counterColor(visit.isFirstCounter);
    final start = visit.checkinAt;
    final now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'End meeting?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Your check-out time will be recorded now.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _counterIcon(visit.isFirstCounter),
                        size: 18,
                        color: color[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${visit.counterLabel} · ${visit.customerName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_clock(start)} → ${_clock(now)}'
                    '${start != null ? '  ·  ${_shortDuration(now.difference(start))}' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Divider(height: 20),
                  Text(
                    remarks,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keep editing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Check Out',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home page reminder ───────────────────────────────────────────────────────

/// Reminds the user on the home page that a counter meeting is still open
/// (checked in, no remark yet). Hidden when there's nothing pending.
class PendingMeetingReminder extends StatelessWidget {
  const PendingMeetingReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final visit = context.watch<LogCustomerVisitController>().openVisit;
    if (visit == null) return const SizedBox.shrink();

    final color = _counterColor(visit.isFirstCounter);
    final start = visit.checkinAt;

    void open() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerVisitLogger()),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[300]!),
              color: Colors.amber[50],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: Colors.amber[900],
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _PulsingDot(color: Colors.amber[800]!),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Meeting remark pending',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${visit.counterLabel} · ${visit.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: color[900],
                        ),
                      ),
                      if (start != null)
                        _Ticker(
                          builder: (_) => Text(
                            'Checked in ${_clock(start)} · '
                            '${_shortDuration(DateTime.now().difference(start))} ago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: open,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Add remark'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
