import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/invoice_list_controller.dart';
import 'package:location_tracker_app/controller/mode_of_pay_controller.dart';
import 'package:location_tracker_app/controller/pay_sales_invoice_controller.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  final Invoice invoice;
  final void Function(double amount, String method) onPaymentSuccess;

  const PaymentPage({
    super.key,
    required this.invoice,
    required this.onPaymentSuccess,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  String _selectedMethod = 'cash'; // card or cash
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _referenceDateController = TextEditingController();
  late AnimationController _amountAnimationController;
  late Animation<double> _amountScaleAnimation;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.outstandingAmount.toStringAsFixed(
      2,
    );

    _amountAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _amountScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _amountAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModeOfPayController>(context, listen: false).fetchmodeofpay();
    });
  }

  void _processPayment() async {
    final controller = Provider.of<PaySalesInvoiceController>(
      context,
      listen: false,
    );

    final paymentAmount = double.tryParse(_amountController.text) ?? 0.0;

    await controller.paySalesInvoice(
      invoice_id: widget.invoice.invoiceId,
      amount: _amountController.text,
      mode_of_payment: _selectedMethod,
      referenceNumber: _referenceNumberController.text,
      referenceDate: _referenceDateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_referenceDateController.text)
          : null,

      // "card" or "cash"
    );

    if (controller.error == null) {
      // Pass the payment amount and method back to the parent
      widget.onPaymentSuccess(paymentAmount, _selectedMethod);
      Navigator.pop(context);
      Provider.of<InvoiceListController>(
        // ignore: use_build_context_synchronously
        context,
        listen: false,
      ).fetchInvoiceList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Payment submitted for processing! ⏳'),
            ],
          ),
          backgroundColor: const Color(0xFF9333EA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${controller.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showItemsModal() {
    final items = widget.invoice.items ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invoice Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Items list
            Expanded(
              child: items.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Color(0xFF667EEA),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Qty: ${item.qty}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '₹${item.rate.toStringAsFixed(2)} each',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(item.qty * item.rate).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Summary footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${widget.invoice.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Display/Input
          AnimatedBuilder(
            animation: _amountScaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _amountScaleAnimation.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF667EEA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          _amountAnimationController.forward().then((_) {
                            _amountAnimationController.reverse();
                          });
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceFields() {
    if (_selectedMethod.isEmpty || _selectedMethod.toLowerCase() == 'cash') {
      return const SizedBox.shrink(); // Don't show for cash payments or no selection
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reference Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Reference Number Field
              TextFormField(
                controller: _referenceNumberController,
                decoration: InputDecoration(
                  labelText: 'Reference Number',
                  hintText: 'Enter transaction reference number',
                  prefixIcon: const Icon(
                    Icons.numbers,
                    color: Color(0xFF667EEA),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF667EEA),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reference Date Field
              TextFormField(
                controller: _referenceDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Reference Date',
                  hintText: 'Select transaction date',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF667EEA),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF667EEA),
                      width: 2,
                    ),
                  ),
                ),
                onTap: () => _selectReferenceDate(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24), // Add spacing after reference fields
      ],
    );
  }

  void _selectReferenceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _referenceDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.invoice.invoiceId,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '₹${widget.invoice.outstandingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.invoice.customer,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: _showItemsModal,
                        child: const Text(
                          'Items',
                          style: TextStyle(color: Color(0xFF667EEA)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input Section
            _buildAmountInput(),
            const SizedBox(height: 24),
            _buildReferenceFields(),
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Consumer<ModeOfPayController>(
              builder: (context, modeController, _) {
                if (modeController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (modeController.error != null) {
                  return Text('Error: ${modeController.error}');
                }
                final modes = modeController.modeofpay!.message
                    .where(
                      (e) => e.execute,
                    ) // only keep items where execute == true
                    .map((e) => e.name)
                    .toList();

                if (modes.isEmpty) {
                  return const Text('No payment methods available');
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: modes.map((mode) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMethod = mode;
                          // Clear reference fields when switching to cash
                          if (mode.toLowerCase() == 'cash') {
                            _referenceNumberController.clear();
                            _referenceDateController.clear();
                          }
                        });
                      },
                      child: Container(
                        width: (MediaQuery.of(context).size.width / 2) - 30,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedMethod == mode
                              ? const Color(0xFF667EEA).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedMethod == mode
                                ? const Color(0xFF667EEA)
                                : Colors.grey[300]!,
                            width: _selectedMethod == mode ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getPaymentIcon(mode),
                              color: _selectedMethod == mode
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mode,
                              style: TextStyle(
                                color: _selectedMethod == mode
                                    ? const Color(0xFF667EEA)
                                    : Colors.grey[600],
                                fontWeight: _selectedMethod == mode
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),
            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Consumer<PaySalesInvoiceController>(
                builder: (context, controller, _) => ElevatedButton(
                  onPressed: (controller.isLoading || _selectedMethod.isEmpty)
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          _selectedMethod.isEmpty
                              ? 'Select Payment Method'
                              : 'Pay ₹${_amountController.text.isEmpty ? '0.00' : _amountController.text}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.qr_code;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.payment; // fallback
    }
  }

  Widget _buildPaymentMethod(String method, String title, IconData icon) {
    bool isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF667EEA) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF667EEA) : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF667EEA) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _amountAnimationController.dispose();
    super.dispose();
  }
}
