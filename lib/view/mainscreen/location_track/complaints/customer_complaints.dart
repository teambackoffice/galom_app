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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Complaint',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // _buildFilterBar(ctrl),
          Expanded(child: _buildBody(ctrl)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(CustomerComplaintController ctrl) {
    final filters = <String?>[null, ...ComplaintOptions.statuses];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final status = filters[i];
          final selected = ctrl.statusFilter == status;
          final color = status == null
              ? ComplaintStyle.navy
              : ComplaintStyle.statusColor(status);
          return GestureDetector(
            onTap: () => ctrl.setStatusFilter(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : ComplaintStyle.border,
                ),
              ),
              child: Text(
                status ?? 'All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : ComplaintStyle.navy,
                ),
              ),
            ),
          );
        },
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

    return RefreshIndicator(
      color: ComplaintStyle.navy,
      onRefresh: ctrl.fetchComplaints,
      child: ctrl.complaints.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildMessage(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    title: 'No complaints',
                    subtitle: ctrl.statusFilter == null
                        ? 'Tap "New Complaint" to raise one.'
                        : 'No ${ctrl.statusFilter} complaints.',
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: ctrl.complaints.length + (ctrl.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i >= ctrl.complaints.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ComplaintStyle.navy,
                      ),
                    ),
                  );
                }
                return _ComplaintCard(complaint: ctrl.complaints[i]);
              },
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

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final statusColor = ComplaintStyle.statusColor(c.status);

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
          decoration: ComplaintStyle.card(),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ComplaintStyle.muted,
                                ),
                              ),
                            ),
                            ComplaintPill(
                              label: c.status.isEmpty ? 'Open' : c.status,
                              color: statusColor,
                              icon: ComplaintStyle.statusIcon(c.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 15,
                              color: ComplaintStyle.muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                c.displayCustomer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (c.priority.isNotEmpty)
                              ComplaintPill(
                                label: c.priority,
                                color: ComplaintStyle.priorityColor(c.priority),
                                icon: Icons.flag_rounded,
                              ),
                            if (c.complaintType.isNotEmpty)
                              ComplaintPill(
                                label: c.complaintType,
                                color: ComplaintStyle.navy,
                                icon: ComplaintStyle.typeIcon(c.complaintType),
                              ),
                            if (c.attachment.isNotEmpty)
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 16,
                                color: ComplaintStyle.muted,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: ComplaintStyle.border),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: ComplaintStyle.muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ComplaintStyle.formatDate(c.complaintDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ComplaintStyle.muted,
                              ),
                            ),
                            const Spacer(),
                            if (c.salesPerson.isNotEmpty) ...[
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: ComplaintStyle.muted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  c.salesPerson,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ComplaintStyle.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
