import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/mainscreen/leave/leave_application.dart';

class LeaveDetailPage extends StatelessWidget {
  final LeaveRequest leave;

  const LeaveDetailPage({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly softer background
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Application Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderStatus(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  if (leave.reason != null && leave.reason!.isNotEmpty)
                    _buildSectionCard('Reason for Leave', leave.reason!),
                  const SizedBox(height: 20),
                  _buildTimeline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Premium Header Section ---
  Widget _buildHeaderStatus() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 32,
            backgroundColor: leave.status.chipBg,
            child: Icon(
              _getStatusIcon(leave.status),
              color: leave.status.chipText,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            leave.status.label.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: leave.status.chipText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            leave.type,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  // --- Info Grid ---
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.calendar_month_rounded, 'Duration', leave.dateRange),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _infoRow(Icons.timer_outlined, 'Total Days', '${leave.days} Days'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _infoRow(
            Icons.history_rounded,
            'Submitted',
            leave.appliedOn ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF888780)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  // --- Section Card ---
  Widget _buildSectionCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888780),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Visual Timeline ---
  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPROVAL FLOW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888780),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _timelineItem('Application Submitted', leave.appliedOn ?? '', true),
          _timelineItem(
            leave.status == LeaveStatus.pending
                ? 'Waiting for Manager'
                : 'Manager Processed',
            leave.status == LeaveStatus.pending ? 'In Progress' : 'Completed',
            leave.status != LeaveStatus.pending,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String title, String subtitle, bool isDone) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? const Color(0xFF3B6D11) : const Color(0xFFD3D1C7),
              size: 20,
            ),
            Container(width: 2, height: 30, color: const Color(0xFFF0F0F0)),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return Icons.verified_rounded;
      case LeaveStatus.rejected:
        return Icons.cancel_rounded;
      case LeaveStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }
}
