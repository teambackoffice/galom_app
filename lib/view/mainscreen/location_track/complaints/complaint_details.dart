import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/customer_complaint_controller.dart';
import 'package:location_tracker_app/modal/customer_complaint_modal.dart';
import 'package:location_tracker_app/service/customer_complaint_service.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:provider/provider.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String complaintName;

  const ComplaintDetailsPage({super.key, required this.complaintName});

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CustomerComplaintController>()
          .fetchDetail(widget.complaintName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CustomerComplaintController>();
    final c = ctrl.detail;

    Widget body;
    if (ctrl.isDetailLoading || (c == null && ctrl.detailError == null)) {
      body = const Center(
        child: CircularProgressIndicator(color: ComplaintStyle.navy),
      );
    } else if (c == null || c.name != widget.complaintName) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFB71C1C),
              ),
              const SizedBox(height: 12),
              Text(
                ctrl.detailError ?? 'Complaint not found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ComplaintStyle.navy),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ctrl.fetchDetail(widget.complaintName),
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
        onRefresh: () => ctrl.fetchDetail(widget.complaintName),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _buildHeader(c),
            const SizedBox(height: 14),
            _section(
              icon: Icons.notes_rounded,
              title: 'Description',
              child: Text(
                c.description.isEmpty ? '-' : c.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _section(
              icon: Icons.info_outline_rounded,
              title: 'Details',
              child: Column(
                children: [
                  _row('Customer', c.displayCustomer),
                  if (c.customerName.isNotEmpty &&
                      c.customerName != c.customer)
                    _row('Customer ID', c.customer),
                  _row('Complaint Date', ComplaintStyle.formatDate(c.complaintDate)),
                  _row('Type', c.complaintType),
                  _row('Priority', c.priority),
                  _row('Sales Invoice', c.salesInvoice),
                  _row('Sales Order', c.salesOrder),
                  _row('Sales Person', c.salesPerson),
                  _row('Raised By', c.raisedBy),
                  _row('Created', ComplaintStyle.formatDateTime(c.creation)),
                ],
              ),
            ),
            if (c.resolution.isNotEmpty ||
                c.resolvedBy.isNotEmpty ||
                c.resolvedOn != null) ...[
              const SizedBox(height: 14),
              _section(
                icon: Icons.task_alt_rounded,
                title: 'Resolution',
                accent: const Color(0xFF00875A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.resolution.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          c.resolution,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    _row('Resolved By', c.resolvedBy),
                    _row('Resolved On', ComplaintStyle.formatDate(c.resolvedOn)),
                  ],
                ),
              ),
            ],
            if (c.attachment.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(
                icon: Icons.attach_file_rounded,
                title: 'Attachment',
                child: c.isImageAttachment
                    ? GestureDetector(
                        onTap: () => _openImage(c, ctrl.sid),
                        child: ComplaintAttachmentImage(
                          url: CustomerComplaintService.attachmentUrl(
                            c.attachment,
                          ),
                          sid: ctrl.sid,
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            color: ComplaintStyle.navy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.attachment.split('/').last,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ComplaintStyle.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: ComplaintAppBar(
        title: 'Complaint',
        subtitle: widget.complaintName,
      ),
      body: body,
    );
  }

  void _openImage(CustomerComplaint c, String? sid) {
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
                CustomerComplaintService.attachmentUrl(c.attachment),
                headers: sid == null ? null : {'Cookie': 'sid=$sid'},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CustomerComplaint c) {
    final statusColor = ComplaintStyle.statusColor(c.status);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ComplaintStyle.statusIcon(c.status),
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (c.priority.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 15,
                      color: c.priority == 'High'
                          ? const Color(0xFFFF8A80)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${c.priority} priority',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            c.subject.isEmpty ? '(No subject)' : c.subject,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.displayCustomer,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              Text(
                ComplaintStyle.formatDate(c.complaintDate),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    Color accent = ComplaintStyle.navy,
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
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
