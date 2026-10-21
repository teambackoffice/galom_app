import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/my_target_controller.dart';
import 'package:location_tracker_app/modal/my_target_modal.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

const Color _kNavy = Color(0xFF1A3A6E);
const Color _kNavyDark = Color(0xFF0D1B3E);
const Color _kAccent = Color(0xFF667EEA);
const Color _kGreen = Color(0xFF10B981);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kRed = Color(0xFFEF4444);
const Color _kText = Color(0xFF2D3436);

final NumberFormat _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
);

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ],
);

class MyTargetPage extends StatefulWidget {
  const MyTargetPage({super.key});

  @override
  State<MyTargetPage> createState() => _MyTargetPageState();
}

class _MyTargetPageState extends State<MyTargetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MyTargetController>(
        context,
        listen: false,
      );
      controller.resetToCurrentMonth();
      controller.fetchTarget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6FA), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<MyTargetController>(
            builder: (context, controller, _) {
              return Column(
                children: [
                  _buildHeader(context),
                  _buildMonthSelector(controller),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchTarget,
                      color: _kAccent,
                      backgroundColor: Colors.white,
                      strokeWidth: 2.5,
                      child: _buildBody(controller),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(MyTargetController controller) {
    if (controller.isLoading) return _buildShimmer();
    if (controller.error != null) {
      return _buildErrorState(controller.error!, controller.fetchTarget);
    }
    final data = controller.target;
    if (data == null) {
      return _buildMessageState(
        Icons.flag_outlined,
        'No Data',
        'Pull down to refresh',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        _buildProgressCard(data),
        const SizedBox(height: 16),
        _buildStatsGrid(data),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Invoices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${data.invoices.length})',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.invoices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No invoices this month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ...data.invoices.map(_buildInvoiceTile),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kNavyDark, _kNavy]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'My Target',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(MyTargetController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.isLoading ? null : controller.previousMonth,
            icon: const Icon(Icons.chevron_left, color: _kNavy),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  controller.selectedMonthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                  ),
                ),
                if (controller.isCurrentMonth)
                  Text(
                    'Current month',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.isLoading ? null : controller.nextMonth,
            icon: const Icon(Icons.chevron_right, color: _kNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(TargetInvoice inv) {
    final date = DateTime.tryParse(inv.postingDate);
    final amountColor = inv.isReturn ? _kRed : const Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (inv.isReturn ? _kRed : _kAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              inv.isReturn
                  ? Icons.assignment_return_rounded
                  : Icons.receipt_rounded,
              color: inv.isReturn ? _kRed : _kAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  inv.customerName.isNotEmpty ? inv.customerName : inv.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null
                      ? DateFormat('dd MMM yyyy').format(date)
                      : inv.postingDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(inv.grandTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 6),
              _statusChip(inv.isReturn ? 'Return' : inv.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    final Color color;
    if (s == 'paid') {
      color = _kGreen;
    } else if (s == 'overdue' || s == 'return' || s == 'cancelled') {
      color = _kRed;
    } else if (s.contains('unpaid') || s.contains('partly')) {
      color = _kAmber;
    } else {
      color = _kAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    Widget box(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          box(180),
          Row(
            children: [
              Expanded(child: box(64)),
              const SizedBox(width: 12),
              Expanded(child: box(64)),
            ],
          ),
          Row(
            children: [
              Expanded(child: box(64)),
              const SizedBox(width: 12),
              Expanded(child: box(64)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 4; i++) box(76),
        ],
      ),
    );
  }

  Widget _buildMessageState(IconData icon, String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildProgressCard(MyTargetModal data) {
  final ring = (data.achievementPercent / 100).clamp(0.0, 1.0);
  final achieved = data.excessAmount > 0;
  final ringColor = achieved ? _kGreen : _kAccent;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        if (!data.hasTarget) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _kAmber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No target set for this month',
                    style: TextStyle(
                      color: _kAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: data.hasTarget ? ring : 0,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.hasTarget
                              ? '${data.achievementPercent.toStringAsFixed(1)}%'
                              : '—',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: data.hasTarget ? ringColor : Colors.grey,
                          ),
                        ),
                        Text(
                          'achieved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _amountRow('Target', data.targetAmount, _kNavy),
                  const SizedBox(height: 10),
                  _amountRow('Achieved', data.achievedAmount, _kGreen),
                  const SizedBox(height: 10),
                  _amountRow('Remaining', data.remainingAmount, _kAmber),
                ],
              ),
            ),
          ],
        ),
        if (data.excessAmount > 0) ...[
          const SizedBox(height: 16),
          _noticeBox(
            'Target achieved 🎉 — ${_currency.format(data.excessAmount)} above target',
            _kGreen,
            Icons.emoji_events_rounded,
          ),
        ] else if (data.remainingAmount > 0 && data.daysLeft > 0) ...[
          const SizedBox(height: 16),
          _noticeBox(
            'Need ${_currency.format(data.requiredPerDay)}/day for the next '
            '${data.daysLeft} day${data.daysLeft == 1 ? '' : 's'}',
            _kAccent,
            Icons.trending_up_rounded,
          ),
        ],
      ],
    ),
  );
}

Widget _amountRow(String label, double value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _currency.format(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ],
  );
}

Widget _noticeBox(String text, Color color, IconData icon) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatsGrid(MyTargetModal data) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.account_balance_wallet_rounded,
              'Collected',
              _currency.format(data.collectedAmount),
              _kGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              Icons.receipt_long_rounded,
              'Invoices',
              '${data.invoiceCount}',
              _kAccent,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.assignment_return_rounded,
              'Returns',
              '${data.returnCount}',
              _kRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              Icons.summarize_rounded,
              'Total incl. tax',
              _currency.format(data.invoicedGrandTotal),
              _kNavy,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _statCard(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Compact current-month target card shown at the top of the Invoices list,
/// kept small so the invoices stay visible. Tap it for the full screen.
class InvoiceTargetSection extends StatelessWidget {
  const InvoiceTargetSection({super.key});

  static final NumberFormat _short = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<MyTargetController>(
      builder: (context, controller, _) {
        final data = controller.currentMonthTarget;

        Future<void> openDetails() async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyTargetPage()),
          );
          controller.fetchCurrentMonthSummary();
        }

        Widget card;
        if (data != null) {
          card = _buildCompactCard(data, openDetails);
        } else if (controller.isSummaryLoading) {
          card = Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else {
          card = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.summaryError ?? 'Could not load your target.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
                TextButton(
                  onPressed: controller.fetchCurrentMonthSummary,
                  child: const Text('Retry', style: TextStyle(color: _kAccent)),
                ),
              ],
            ),
          );
        }

        return Padding(padding: const EdgeInsets.only(bottom: 12), child: card);
      },
    );
  }

  Widget _buildCompactCard(MyTargetModal data, VoidCallback onTap) {
    const doneColor = Color(0xFF6EE7B7);
    final done = data.excessAmount > 0;
    final ringColor = done ? doneColor : Colors.white;
    final ring = (data.achievementPercent / 100).clamp(0.0, 1.0);
    final month = data.monthLabel.isNotEmpty
        ? data.monthLabel
        : DateFormat('MMMM yyyy').format(DateTime.now());

    String? note;
    IconData noteIcon = Icons.trending_up_rounded;
    if (!data.hasTarget) {
      note = 'No target set for this month';
      noteIcon = Icons.info_outline;
    } else if (done) {
      note = 'Target achieved 🎉  ${_short.format(data.excessAmount)} above';
      noteIcon = Icons.emoji_events_rounded;
    } else if (data.remainingAmount > 0 && data.daysLeft > 0) {
      note =
          'Need ${_short.format(data.requiredPerDay)}/day for ${data.daysLeft} '
          'day${data.daysLeft == 1 ? '' : 's'}';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kNavyDark, _kNavy, Color(0xFF2A4F8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + month pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'My Target',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    month,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Ring + achieved amount
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: data.hasTarget ? ring : 0,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(ringColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                data.hasTarget
                                    ? '${data.achievementPercent.toStringAsFixed(0)}%'
                                    : '—',
                                style: TextStyle(
                                  color: ringColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Text(
                              'done',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achieved',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _short.format(data.achievedAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.hasTarget
                            ? 'of ${_short.format(data.targetAmount)} target'
                            : 'No target set',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat tiles
            Row(
              children: [
                _miniFigure(
                  done ? 'Above target' : 'Pending',
                  _short.format(done ? data.excessAmount : data.remainingAmount),
                  done ? doneColor : const Color(0xFFFCD34D),
                ),
                const SizedBox(width: 8),
                _miniFigure(
                  'Collected',
                  _short.format(data.collectedAmount),
                  Colors.white,
                ),
                const SizedBox(width: 8),
                _miniFigure('Invoices', '${data.invoiceCount}', Colors.white),
              ],
            ),

            if (note != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (done ? doneColor : Colors.white).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      noteIcon,
                      size: 16,
                      color: done ? doneColor : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: done ? doneColor : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniFigure(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
