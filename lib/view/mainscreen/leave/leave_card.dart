import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/mainscreen/leave/leave_application.dart';
import 'package:location_tracker_app/view/mainscreen/leave/leave_detail_page.dart'
    hide LeaveDetailPage;

class LeaveCard extends StatelessWidget {
  final LeaveRequest leave;

  const LeaveCard({super.key, required this.leave});

  String get _daysLabel {
    final d = leave.days;
    return '${d % 1 == 0 ? d.toInt() : d} ${d == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailPage(leave: leave),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: leave.status.barColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              leave.type,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            _StatusChip(status: leave.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              leave.dateRange,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _daysLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF888780),
                              ),
                            ),
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

class _StatusChip extends StatelessWidget {
  final LeaveStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.chipText,
        ),
      ),
    );
  }
}

// --- Apply Leave Bottom Sheet ---
class LeaveApplySheet extends StatefulWidget {
  const LeaveApplySheet({super.key});

  @override
  State<LeaveApplySheet> createState() => _LeaveApplySheetState();
}

class _LeaveApplySheetState extends State<LeaveApplySheet> {
  final List<String> leaveTypes = const [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Compensatory Leave',
  ];

  String selectedType = 'Annual Leave';
  DateTime? fromDate;
  DateTime? toDate;
  bool isHalfDay = false;
  String halfDaySession = 'Morning'; // 'Morning' or 'Afternoon'
  final TextEditingController reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A1A1A),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(picked)) toDate = null;
          // When half day is on, lock toDate = fromDate
          if (isHalfDay) toDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  String _month(int m) {
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
    return months[m - 1];
  }

  void _onHalfDayToggled(bool value) {
    setState(() {
      isHalfDay = value;
      if (isHalfDay) {
        // Half day: lock to single date — set toDate = fromDate
        if (fromDate != null) toDate = fromDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3D1C7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'New leave application',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(height: 0.5, color: const Color(0xFFE0E0E0)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave type
                    _fieldLabel('Leave type'),
                    const SizedBox(height: 6),
                    _DropdownField(
                      value: selectedType,
                      items: leaveTypes,
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),

                    // Half Day Toggle Row
                    _HalfDayToggleRow(
                      isHalfDay: isHalfDay,
                      onToggled: _onHalfDayToggled,
                    ),

                    // Session selector (only when half day is on)
                    if (isHalfDay) ...[
                      const SizedBox(height: 12),
                      _SessionSelector(
                        selected: halfDaySession,
                        onSelected: (s) => setState(() => halfDaySession = s),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Date range
                    _fieldLabel(isHalfDay ? 'Date' : 'Date range'),
                    const SizedBox(height: 6),
                    if (isHalfDay)
                      // Single date picker for half day
                      _DateTile(
                        label: 'Date',
                        value: _formatDate(fromDate),
                        hasValue: fromDate != null,
                        onTap: () => _pickDate(true),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _DateTile(
                              label: 'From',
                              value: _formatDate(fromDate),
                              hasValue: fromDate != null,
                              onTap: () => _pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateTile(
                              label: 'To',
                              value: _formatDate(toDate),
                              hasValue: toDate != null,
                              onTap: () => _pickDate(false),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),
                    // Reason
                    Row(
                      children: [
                        _fieldLabel('Reason'),
                        const SizedBox(width: 4),
                        const Text(
                          '(optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888780),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a note for your manager…',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888780),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD3D1C7),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF888780),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit application',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888780),
        letterSpacing: 0.3,
      ),
    );
  }
}

// --- Half Day Toggle Row ---
class _HalfDayToggleRow extends StatelessWidget {
  final bool isHalfDay;
  final ValueChanged<bool> onToggled;

  const _HalfDayToggleRow({required this.isHalfDay, required this.onToggled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggled(!isHalfDay),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isHalfDay ? const Color(0xFFF0F6E8) : const Color(0xFFFAFAFA),
          border: Border.all(
            color: isHalfDay
                ? const Color(0xFF3B6D11)
                : const Color(0xFFD3D1C7),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isHalfDay
                    ? const Color(0xFFEAF3DE)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.wb_twilight_rounded,
                size: 18,
                color: isHalfDay
                    ? const Color(0xFF3B6D11)
                    : const Color(0xFF888780),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Half day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isHalfDay
                          ? const Color(0xFF3B6D11)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Apply for 0.5 day leave',
                    style: TextStyle(
                      fontSize: 11,
                      color: isHalfDay
                          ? const Color(0xFF5A9E20)
                          : const Color(0xFF888780),
                    ),
                  ),
                ],
              ),
            ),
            // Custom toggle switch
            _ToggleSwitch(value: isHalfDay),
          ],
        ),
      ),
    );
  }
}

// --- Minimal Toggle Switch ---
class _ToggleSwitch extends StatelessWidget {
  final bool value;

  const _ToggleSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        color: value ? const Color(0xFF3B6D11) : const Color(0xFFD3D1C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: value ? 20 : 2,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Session Selector (Morning / Afternoon) ---
class _SessionSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _SessionSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SESSION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888780),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SessionOption(
                label: 'Morning',
                icon: Icons.wb_sunny_outlined,
                description: 'First half',
                isSelected: selected == 'Morning',
                onTap: () => onSelected('Morning'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SessionOption(
                label: 'Afternoon',
                icon: Icons.wb_cloudy_outlined,
                description: 'Second half',
                isSelected: selected == 'Afternoon',
                onTap: () => onSelected('Afternoon'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionOption({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F6E8) : const Color(0xFFFAFAFA),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B6D11)
                : const Color(0xFFD3D1C7),
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFF888780),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888780),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Color(0xFF3B6D11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Dropdown Field (unchanged) ---
class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF888780),
            size: 20,
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          onChanged: onChanged,
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
        ),
      ),
    );
  }
}

// --- Date Tile (unchanged) ---
class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasValue
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF888780),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Leave Detail Page ---

// Note: Ensure your imports for controllers and models match your project structure
// import 'package:location_tracker_app/controller/leave_application_controller.dart';
// import 'package:location_tracker_app/modal/leave_applicatrion_modal.dart';
