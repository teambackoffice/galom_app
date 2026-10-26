import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/customer_complaint_controller.dart';
import 'package:location_tracker_app/controller/customer_list_controller.dart';
import 'package:location_tracker_app/modal/customer_complaint_modal.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:provider/provider.dart';

class CreateComplaintPage extends StatefulWidget {
  const CreateComplaintPage({super.key});

  @override
  State<CreateComplaintPage> createState() => _CreateComplaintPageState();
}

class _CreateComplaintPageState extends State<CreateComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  MessageElement? _customer;
  bool _customerError = false;
  DateTime _date = DateTime.now();
  File? _attachment;
  bool _attachmentIsVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customers = context.read<GetCustomerListController>();
      if (customers.customerlist == null && !customers.isLoading) {
        customers.fetchCustomerList();
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<MessageElement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CustomerPickerSheet(),
    );
    if (picked != null) {
      setState(() {
        _customer = picked;
        _customerError = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: ComplaintStyle.navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file != null) {
        setState(() {
          _attachment = File(file.path);
          _attachmentIsVideo = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (file != null) {
        setState(() {
          _attachment = File(file.path);
          _attachmentIsVideo = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick video: $e')),
      );
    }
  }

  void _showAttachmentOptions() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: ComplaintStyle.navy,
                ),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAttachment(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: ComplaintStyle.navy,
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAttachment(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.videocam_outlined,
                  color: ComplaintStyle.navy,
                ),
                title: const Text('Record video'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library_outlined,
                  color: ComplaintStyle.navy,
                ),
                title: const Text('Choose video from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _customerError = _customer == null);
    if (!formOk || _customer == null) return;

    final ctrl = context.read<CustomerComplaintController>();
    final created = await ctrl.createComplaint(
      CreateComplaintRequest(
        customer: _customer!.name,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        complaintDate: DateFormat('yyyy-MM-dd').format(_date),
      ),
      attachment: _attachment,
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.submitError ?? 'Failed to raise complaint'),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<CustomerComplaintController>().isSubmitting;

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: const ComplaintAppBar(
        title: 'New Complaint',
        subtitle: 'Raise an issue on behalf of a customer',
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AbsorbPointer(
          absorbing: isSubmitting,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _card(
                  icon: Icons.storefront_outlined,
                  title: 'Customer',
                  children: [_buildCustomerField()],
                ),
                const SizedBox(height: 14),
                _card(
                  icon: Icons.edit_note_rounded,
                  title: 'Complaint',
                  children: [
                    _label('Subject', required: true),
                    _textField(
                      controller: _subjectController,
                      hint: 'e.g. Damaged goods received',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a subject'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Description', required: true),
                    _textField(
                      controller: _descriptionController,
                      hint: 'Describe what happened...',
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please describe the complaint'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Complaint Date'),
                    _buildDateField(),
                  ],
                ),
                const SizedBox(height: 14),
                _card(
                  icon: Icons.attach_file_rounded,
                  title: 'Attachment',
                  trailing: 'Optional',
                  children: [_buildAttachment()],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ComplaintStyle.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          ComplaintStyle.navy.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Submit Complaint',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
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

  // ── Sections ────────────────────────────────────────────────────────────────

  Widget _buildCustomerField() {
    final hasCustomer = _customer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickCustomer,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasCustomer
                  ? ComplaintStyle.navy.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _customerError
                    ? const Color(0xFFB71C1C)
                    : hasCustomer
                        ? ComplaintStyle.navy.withOpacity(0.3)
                        : ComplaintStyle.border,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ComplaintStyle.navy.withOpacity(0.08),
                  child: hasCustomer
                      ? Text(
                          _initials(_customer!.customerName),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ComplaintStyle.navy,
                          ),
                        )
                      : const Icon(
                          Icons.person_search_rounded,
                          color: ComplaintStyle.navy,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCustomer
                            ? _customer!.customerName
                            : 'Select customer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              hasCustomer ? FontWeight.w700 : FontWeight.w500,
                          color: hasCustomer
                              ? ComplaintStyle.navy
                              : ComplaintStyle.muted,
                        ),
                      ),
                      if (hasCustomer) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            _customer!.name,
                            if (_customer!.mobileNo?.isNotEmpty ?? false)
                              _customer!.mobileNo!,
                          ].join('  •  '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ComplaintStyle.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  hasCustomer ? Icons.swap_horiz_rounded : Icons.chevron_right,
                  color: ComplaintStyle.muted,
                ),
              ],
            ),
          ),
        ),
        if (_customerError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'Please select a customer',
              style: TextStyle(fontSize: 12, color: Color(0xFFB71C1C)),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ComplaintStyle.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: ComplaintStyle.navy,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEE, dd MMM yyyy').format(_date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ComplaintStyle.navy,
              ),
            ),
            const Spacer(),
            const Icon(Icons.expand_more_rounded, color: ComplaintStyle.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment() {
    if (_attachment == null) {
      return InkWell(
        onTap: _showAttachmentOptions,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ComplaintStyle.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ComplaintStyle.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 28,
                color: ComplaintStyle.navy,
              ),
              SizedBox(height: 8),
              Text(
                'Add a photo or video of the issue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ComplaintStyle.navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Camera or gallery',
                style: TextStyle(fontSize: 11.5, color: ComplaintStyle.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _attachmentIsVideo
              ? _buildVideoPreview()
              : Image.file(
                  _attachment!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _imageAction(Icons.refresh_rounded, _showAttachmentOptions),
              const SizedBox(width: 8),
              _imageAction(
                Icons.close_rounded,
                () => setState(() => _attachment = null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    final file = _attachment!;
    final sizeMb = file.lengthSync() / (1024 * 1024);
    return Container(
      height: 180,
      width: double.infinity,
      color: ComplaintStyle.navy,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            file.path.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Video · ${sizeMb.toStringAsFixed(1)} MB',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── Building blocks ────────────────────────────────────────────────────────

  Widget _imageAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    String? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ComplaintStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ComplaintStyle.navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: ComplaintStyle.navy),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ComplaintStyle.navy,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: ComplaintStyle.muted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFB71C1C)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14, color: ComplaintStyle.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFADB3C2)),
        isDense: true,
        contentPadding: const EdgeInsets.all(14),
        border: border(ComplaintStyle.border),
        enabledBorder: border(ComplaintStyle.border),
        focusedBorder: border(ComplaintStyle.navy, 1.5),
        errorBorder: border(const Color(0xFFB71C1C)),
        focusedErrorBorder: border(const Color(0xFFB71C1C), 1.5),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GetCustomerListController>();
    final all = ctrl.customerlist?.message.message ?? <MessageElement>[];
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((c) =>
                c.customerName.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q) ||
                (c.mobileNo ?? '').contains(q))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ComplaintStyle.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ComplaintStyle.navy,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: ComplaintStyle.background,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ctrl.isLoading && all.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ComplaintStyle.navy,
                      ),
                    )
                  : ctrl.error != null && all.isEmpty
                      ? Center(
                          child: TextButton.icon(
                            onPressed: ctrl.fetchCustomerList,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Could not load customers. Retry'),
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No customers found',
                                style: TextStyle(color: ComplaintStyle.muted),
                              ),
                            )
                          : ListView.separated(
                              controller: scroll,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 72,
                                color: ComplaintStyle.border,
                              ),
                              itemBuilder: (_, i) {
                                final c = filtered[i];
                                return ListTile(
                                  onTap: () => Navigator.pop(context, c),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        ComplaintStyle.navy.withOpacity(0.08),
                                    child: Text(
                                      c.customerName.isNotEmpty
                                          ? c.customerName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: ComplaintStyle.navy,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    c.customerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ComplaintStyle.navy,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      c.name,
                                      if (c.mobileNo?.isNotEmpty ?? false)
                                        c.mobileNo!,
                                    ].join('  •  '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
