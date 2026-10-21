import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/customer_complaint_controller.dart';
import 'package:location_tracker_app/modal/customer_complaint_modal.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_details.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/create_complaint.dart';
import 'package:provider/provider.dart';

class CustomerComplaintsPage extends StatefulWidget {
  const CustomerComplaintsPage({super.key});

  @override
  State<CustomerComplaintsPage> createState() => _CustomerComplaintsPageState();
}

class _CustomerComplaintsPageState extends State<CustomerComplaintsPage> {
  final ScrollController _scroll = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<CustomerComplaintController>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerComplaintController>().fetchComplaints();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<CustomerComplaint>(
      context,
      MaterialPageRoute(builder: (_) => const CreateComplaintPage()),
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint ${created.name} raised'),
          backgroundColor: const Color(0xFF00875A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CustomerComplaintController>();

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: const ComplaintAppBar(
        title: 'Customer Complaints',
        subtitle: 'Track and raise customer issues',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: ComplaintStyle.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Complaint',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(ctrl),
    );
  }

  List<CustomerComplaint> _visible(CustomerComplaintController ctrl) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return ctrl.complaints;
    return ctrl.complaints
        .where((c) =>
            c.subject.toLowerCase().contains(q) ||
            c.displayCustomer.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildSummary(CustomerComplaintController ctrl) {
    int countOf(String status) =>
        ctrl.complaints.where((c) => c.status == status).length;
    final pending = countOf('Open') + countOf('In Progress');
    final resolved = countOf('Resolved') + countOf('Closed');

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
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ctrl.complaints.length}',
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Total complaints',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryStat(
                label: 'Open',
                value: countOf('Open'),
                color: const Color(0xFF64B5F6),
              ),
              _summaryStat(
                label: 'In Progress',
                value: countOf('In Progress'),
                color: const Color(0xFFFFB74D),
              ),
              _summaryStat(
                label: 'Resolved',
                value: resolved,
                color: const Color(0xFF81C784),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$pending awaiting resolution',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStat({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: label == 'Resolved' ? 0 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim()),
      style: const TextStyle(fontSize: 14, color: ComplaintStyle.navy),
      decoration: InputDecoration(
        hintText: 'Search subject, customer or ID',
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFADB3C2)),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ComplaintStyle.muted,
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBody(CustomerComplaintController ctrl) {
    if (ctrl.isLoading && ctrl.complaints.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ComplaintStyle.navy),
      );
    }

    if (ctrl.error != null && ctrl.complaints.isEmpty) {
      return _buildMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load complaints',
        subtitle: ctrl.error!,
        action: OutlinedButton.icon(
          onPressed: ctrl.fetchComplaints,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: OutlinedButton.styleFrom(foregroundColor: ComplaintStyle.navy),
        ),
      );
    }

    final items = _visible(ctrl);

    return RefreshIndicator(
      color: ComplaintStyle.navy,
      onRefresh: ctrl.fetchComplaints,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _buildSummary(ctrl),
          if (ctrl.complaints.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSearch(),
          ],
          const SizedBox(height: 18),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                _query.isEmpty ? 'Recent complaints' : '${items.length} results',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ComplaintStyle.navy,
                ),
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _buildMessage(
                icon: _query.isEmpty
                    ? Icons.sentiment_satisfied_alt_rounded
                    : Icons.search_off_rounded,
                title: _query.isEmpty ? 'No complaints yet' : 'No matches',
                subtitle: _query.isEmpty
                    ? 'Tap "New Complaint" to raise one.'
                    : 'Try a different search.',
              ),
            ),
          for (final c in items) ...[
            _ComplaintCard(complaint: c),
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
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final CustomerComplaint complaint;

  const _ComplaintCard({required this.complaint});

  String get _initial {
    final n = complaint.displayCustomer.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final status = c.status.isEmpty ? 'Open' : c.status;
    final statusColor = ComplaintStyle.statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailsPage(complaintName: c.name),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: ComplaintStyle.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.subject.isEmpty ? '(No subject)' : c.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ComplaintStyle.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.displayCustomer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ComplaintPill(
                    label: status,
                    color: statusColor,
                    icon: ComplaintStyle.statusIcon(status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ComplaintStyle.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color: ComplaintStyle.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ComplaintStyle.muted,
                      ),
                    ),
                    const Spacer(),
                    if (c.attachment.isNotEmpty) ...[
                      const Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: ComplaintStyle.muted,
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: ComplaintStyle.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ComplaintStyle.formatDate(c.complaintDate),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: ComplaintStyle.muted,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: ComplaintStyle.muted,
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
