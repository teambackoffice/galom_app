import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/create_leave_controller.dart';
import 'package:location_tracker_app/controller/leave_application_controller.dart';
import 'package:provider/provider.dart';
import 'package:location_tracker_app/modal/leave_applicatrion_modal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Entry Point Widget ---
class LeaveApplication extends StatelessWidget {
  const LeaveApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GetLeaveApplicationController()),
        ChangeNotifierProvider(
          create: (_) => CreateLeaveApplicationController(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const LeaveListPage(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A1A),
        brightness: Brightness.light,
      ),
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    );
  }
}

// --- Status Mapping ---
LeaveStatus _mapStatus(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return LeaveStatus.approved;
    case 'rejected':
      return LeaveStatus.rejected;
    default:
      return LeaveStatus.pending;
  }
}

String _formatDateRange(DateTime from, DateTime to) {
  final months = [
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
  if (from.year == to.year && from.month == to.month && from.day == to.day) {
    return '${from.day} ${months[from.month - 1]}';
  }
  return '${from.day} ${months[from.month - 1]} – ${to.day} ${months[to.month - 1]}';
}

String _formatPostedDate(DateTime date) {
  final months = [
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
  return '${date.day} ${months[date.month - 1]}, ${date.year}';
}

String _formatApiDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// --- Data Model ---
class LeaveRequest {
  final String type;
  final String dateRange;
  final double days;
  final LeaveStatus status;
  final String? appliedOn;
  final String? reason;

  const LeaveRequest({
    required this.type,
    required this.dateRange,
    required this.days,
    required this.status,
    this.appliedOn,
    this.reason,
  });

  factory LeaveRequest.fromApplication(Application app) {
    return LeaveRequest(
      type: app.leaveType,
      dateRange: _formatDateRange(app.fromDate, app.toDate),
      days: app.totalLeaveDays.toDouble(),
      status: _mapStatus(app.status),
      appliedOn: _formatPostedDate(app.postingDate),
    );
  }
}

enum LeaveStatus { approved, pending, rejected }

extension LeaveStatusExt on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  Color get barColor {
    switch (this) {
      case LeaveStatus.approved:
        return const Color(0xFF3B6D11);
      case LeaveStatus.pending:
        return const Color(0xFFBA7517);
      case LeaveStatus.rejected:
        return const Color(0xFFE24B4A);
    }
  }

  Color get chipBg {
    switch (this) {
      case LeaveStatus.approved:
        return const Color(0xFFEAF3DE);
      case LeaveStatus.pending:
        return const Color(0xFFFAEEDA);
      case LeaveStatus.rejected:
        return const Color(0xFFFCEBEB);
    }
  }

  Color get chipText {
    switch (this) {
      case LeaveStatus.approved:
        return const Color(0xFF3B6D11);
      case LeaveStatus.pending:
        return const Color(0xFF854F0B);
      case LeaveStatus.rejected:
        return const Color(0xFFA32D2D);
    }
  }
}

// --- Main List Page ---
// ─── Replace the entire LeaveListPage class ────────────────────────────────

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  String _filter = 'All';
  final _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  static const _months = [
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

  String _monthKey(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetLeaveApplicationController>().fetchLeaveApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Consumer<GetLeaveApplicationController>(
          builder: (context, controller, _) => Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody(controller)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon container with gradient — same colours as Sales Orders
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
            child: const Icon(Icons.event_note, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Leaves',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GetLeaveApplicationController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A1A1A),
          strokeWidth: 2,
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFFD3D1C7),
              ),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888780)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: controller.fetchLeaveApplications,
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final apps = controller.leaveData?.message?.applications;
    if (apps == null || apps.isEmpty) return _buildEmpty();

    // Filter using Application.status directly (before conversion)
    final filtered = _filter == 'All'
        ? apps
        : apps
              .where((a) => a.status.toLowerCase() == _filter.toLowerCase())
              .toList();

    if (filtered.isEmpty) return _buildEmpty();

    // Group by month using Application.fromDate
    final groups = <String, List<Application>>{};
    for (final a in filtered) {
      final key = _monthKey(a.fromDate);
      (groups[key] ??= []).add(a);
    }

    // Flatten: String month label + Application items
    final items = <Object>[];
    groups.forEach((month, list) {
      items.add(month);
      items.addAll(list);
    });

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () => controller.fetchLeaveApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item is String) {
            // Month header
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 2),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888780),
                  letterSpacing: 0.5,
                ),
              ),
            );
          }
          return LeaveCard(
            leave: LeaveRequest.fromApplication(item as Application),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFD3D1C7)),
          SizedBox(height: 12),
          Text(
            'No leave applications yet',
            style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ChangeNotifierProvider(
              create: (_) => CreateLeaveApplicationController(),
              child: const LeaveApplySheet(),
            ),
          ),
          backgroundColor: const Color(0xFF1A3A6E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Apply for leave',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ─── Replace the entire LeaveCard class ───────────────────────────────────

class LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  const LeaveCard({super.key, required this.leave});

  String get _daysLabel {
    final d = leave.days;
    final n = d % 1 == 0 ? d.toInt().toString() : '0.5';
    return '$n ${d == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeaveDetailPage(leave: leave)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored accent bar
                Container(width: 4, color: leave.status.barColor),

                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: leave type + status chip
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                leave.type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(status: leave.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: calendar icon + date range + days pill
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                leave.dateRange,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _daysLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888780),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Row 3: applied on date (if present)
                        if (leave.appliedOn != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Colors.grey[350],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Applied ${leave.appliedOn}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Chevron
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey[300],
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
  final List<String> leaveTypes = const ['Sick Leave', 'Casual Leave'];

  String selectedType = 'Sick Leave';
  DateTime? fromDate;
  DateTime? toDate;
  bool isHalfDay = false;
  String halfDaySession = 'Morning';
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
      if (isHalfDay && fromDate != null) {
        toDate = fromDate;
      }
    });
  }

  String? _validate() {
    if (fromDate == null) return 'Please select a start date';
    if (!isHalfDay && toDate == null) return 'Please select an end date';
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    const storage = FlutterSecureStorage();
    final employee = await storage.read(key: 'employee_id') ?? '';

    if (!mounted) return;

    if (employee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee ID not found. Please login again.'),
          backgroundColor: Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = context.read<CreateLeaveApplicationController>();

    final int halfDayValue = isHalfDay ? 1 : 0;
    final String? halfDayDateValue = isHalfDay && fromDate != null
        ? _formatApiDate(fromDate!)
        : null;
    final String fromDateStr = _formatApiDate(fromDate!);
    final String toDateStr = isHalfDay ? fromDateStr : _formatApiDate(toDate!);

    await controller.submitLeaveApplication(
      employee: employee,
      leaveType: selectedType,
      fromDate: fromDateStr,
      toDate: toDateStr,
      description: reasonController.text.trim(),
      halfDay: halfDayValue,
      halfDayDate: halfDayDateValue,
    );

    if (!mounted) return;

    if (controller.isSuccess) {
      final listPageMessenger = ScaffoldMessenger.of(context);
      final listPageController = context.read<GetLeaveApplicationController>();

      Navigator.pop(context);
      listPageController.fetchLeaveApplications();

      listPageMessenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Leave application submitted successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF3B6D11),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
                    _fieldLabel('Leave type'),
                    const SizedBox(height: 6),
                    _DropdownField(
                      value: selectedType,
                      items: leaveTypes,
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    _HalfDayToggleRow(
                      isHalfDay: isHalfDay,
                      onToggled: _onHalfDayToggled,
                    ),
                    if (isHalfDay) ...[
                      const SizedBox(height: 12),
                      _SessionSelector(
                        selected: halfDaySession,
                        onSelected: (s) => setState(() => halfDaySession = s),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _fieldLabel(isHalfDay ? 'Date' : 'Date range'),
                    const SizedBox(height: 6),
                    if (isHalfDay)
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
                    Consumer<CreateLeaveApplicationController>(
                      builder: (context, createCtrl, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: createCtrl.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3A6E),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF888780),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: createCtrl.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit Application',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        );
                      },
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

// --- Dropdown Field ---
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

// --- Date Tile ---
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
class LeaveDetailPage extends StatelessWidget {
  final LeaveRequest leave;

  const LeaveDetailPage({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
