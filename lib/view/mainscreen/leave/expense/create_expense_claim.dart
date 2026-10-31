import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/expense_claim_controller.dart';
import 'package:location_tracker_app/modal/expense_claim_modal.dart';
import 'package:location_tracker_app/view/mainscreen/leave/expense/expense_style.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/complaints/complaint_style.dart';
import 'package:provider/provider.dart';

/// Form state for one expense line.
class _LineDraft {
  String? type;
  DateTime date;
  final amount = TextEditingController();
  final description = TextEditingController();

  _LineDraft(this.date);

  double get value => double.tryParse(amount.text.trim()) ?? 0;

  void dispose() {
    amount.dispose();
    description.dispose();
  }
}

class CreateExpenseClaimPage extends StatefulWidget {
  const CreateExpenseClaimPage({super.key});

  @override
  State<CreateExpenseClaimPage> createState() => _CreateExpenseClaimPageState();
}

class _CreateExpenseClaimPageState extends State<CreateExpenseClaimPage> {
  static const int _maxReceipts = 10;

  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime _postingDate = DateTime.now();
  final List<_LineDraft> _lines = [_LineDraft(DateTime.now())];
  final List<File> _receipts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ExpenseClaimController>();
      if (ctrl.expenseTypes.isEmpty) ctrl.fetchExpenseTypes();
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _total => _lines.fold(0, (sum, l) => sum + l.value);

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: ComplaintStyle.navy),
        ),
        child: child!,
      ),
    );
  }

  void _addLine() {
    setState(() => _lines.add(_LineDraft(_postingDate)));
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index).dispose());
  }

  Future<void> _addReceipt(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(
          imageQuality: 70,
          maxWidth: 1600,
        );
        if (files.isEmpty) return;
        setState(() {
          for (final f in files) {
            if (_receipts.length >= _maxReceipts) break;
            _receipts.add(File(f.path));
          }
        });
      } else {
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1600,
        );
        if (file != null) setState(() => _receipts.add(File(file.path)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  void _showReceiptOptions() {
    FocusScope.of(context).unfocus();
    if (_receipts.length >= _maxReceipts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 10 receipts')),
      );
      return;
    }
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
                  _addReceipt(ImageSource.camera);
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
                  _addReceipt(ImageSource.gallery);
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final remark = _remarkController.text.trim();
    final ctrl = context.read<ExpenseClaimController>();
    final created = await ctrl.createClaim(
      postingDate: ExpenseStyle.apiDate(_postingDate),
      remark: remark.isEmpty ? null : remark,
      receipts: List.of(_receipts),
      lines: _lines
          .map(
            (l) => NewExpenseLine(
              expenseType: l.type!,
              amount: l.value,
              expenseDate: ExpenseStyle.apiDate(l.date),
              description: l.description.text.trim().isEmpty
                  ? null
                  : l.description.text.trim(),
            ),
          )
          .toList(),
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.submitError ?? 'Failed to submit claim'),
          backgroundColor: ExpenseStyle.rejected,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExpenseClaimController>();

    return Scaffold(
      backgroundColor: ComplaintStyle.background,
      appBar: const ComplaintAppBar(
        title: 'New Expense Claim',
        subtitle: 'Sent to your approver after submitting',
      ),
      bottomNavigationBar: _buildBottomBar(ctrl.isSubmitting),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AbsorbPointer(
          absorbing: ctrl.isSubmitting,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _card(
                  icon: Icons.event_note_rounded,
                  title: 'Claim',
                  children: [
                    _label('Posting Date'),
                    _dateField(_postingDate, () async {
                      final d = await _pickDate(_postingDate);
                      if (d != null) setState(() => _postingDate = d);
                    }),
                    const SizedBox(height: 16),
                    _label('Remark'),
                    _textField(
                      controller: _remarkController,
                      hint: 'e.g. Field visit expenses',
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Expenses (${_lines.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ComplaintStyle.navy,
                    ),
                  ),
                ),
                for (var i = 0; i < _lines.length; i++) ...[
                  _buildLine(i, ctrl),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add another expense'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ComplaintStyle.navy,
                    backgroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: ComplaintStyle.navy.withOpacity(0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 18),
                _card(
                  icon: Icons.receipt_rounded,
                  title: 'Receipts',
                  trailing: _receipts.isEmpty
                      ? 'Optional'
                      : '${_receipts.length}/$_maxReceipts',
                  children: [_buildReceipts()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLine(int index, ExpenseClaimController ctrl) {
    final line = _lines[index];
    return Container(
      key: ObjectKey(line),
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
                child: Icon(
                  ExpenseStyle.typeIcon(line.type ?? ''),
                  size: 17,
                  color: ComplaintStyle.navy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Expense ${index + 1}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ComplaintStyle.navy,
                ),
              ),
              const Spacer(),
              if (_lines.length > 1)
                IconButton(
                  onPressed: () => _removeLine(index),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: ExpenseStyle.rejected,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _label('Expense Type', required: true),
          _buildTypeDropdown(line, ctrl),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Amount', required: true),
                    _textField(
                      controller: line.amount,
                      hint: '0.00',
                      prefix: '₹ ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Enter amount';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date'),
                    _dateField(line.date, () async {
                      final d = await _pickDate(line.date);
                      if (d != null) setState(() => line.date = d);
                    }, compact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Description'),
          _textField(
            controller: line.description,
            hint: 'e.g. Bus fare to Kozhikode',
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(_LineDraft line, ExpenseClaimController ctrl) {
    if (ctrl.isTypesLoading && ctrl.expenseTypes.isEmpty) {
      return Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ComplaintStyle.border),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (ctrl.expenseTypes.isEmpty) {
      return InkWell(
        onTap: ctrl.fetchExpenseTypes,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ExpenseStyle.rejected.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: ExpenseStyle.rejected,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ctrl.typesError ?? 'No expense types found. Tap to retry.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ExpenseStyle.rejected,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: ctrl.expenseTypes.contains(line.type) ? line.type : null,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: ComplaintStyle.muted),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Colors.white,
      decoration: _inputDecoration('Select type'),
      style: const TextStyle(fontSize: 14, color: ComplaintStyle.navy),
      items: ctrl.expenseTypes
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Icon(
                    ExpenseStyle.typeIcon(t),
                    size: 18,
                    color: ComplaintStyle.navy,
                  ),
                  const SizedBox(width: 10),
                  Flexible(child: Text(t, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => line.type = v),
      validator: (v) => v == null ? 'Select an expense type' : null,
    );
  }

  Widget _buildReceipts() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _receipts.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _receipts[i],
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _receipts.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (_receipts.length < _maxReceipts)
          InkWell(
            onTap: _showReceiptOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
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
                    size: 24,
                    color: ComplaintStyle.navy,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ComplaintStyle.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(bool isSubmitting) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: ComplaintStyle.navy.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total claim',
                  style: TextStyle(fontSize: 12, color: ComplaintStyle.muted),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ExpenseStyle.money(_total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ComplaintStyle.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ComplaintStyle.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ComplaintStyle.navy.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Submit Claim',
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
    );
  }

  // ── Building blocks ────────────────────────────────────────────────────────

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
                style: TextStyle(color: ExpenseStyle.rejected),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(DateTime date, VoidCallback onTap, {bool compact = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ComplaintStyle.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: ComplaintStyle.navy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat(compact ? 'dd MMM yyyy' : 'EEE, dd MMM yyyy')
                    .format(date),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ComplaintStyle.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFADB3C2)),
      prefixText: prefix,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ComplaintStyle.navy,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.all(14),
      border: border(ComplaintStyle.border),
      enabledBorder: border(ComplaintStyle.border),
      focusedBorder: border(ComplaintStyle.navy, 1.5),
      errorBorder: border(ExpenseStyle.rejected),
      focusedErrorBorder: border(ExpenseStyle.rejected, 1.5),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14, color: ComplaintStyle.navy),
      decoration: _inputDecoration(hint, prefix: prefix),
    );
  }
}
