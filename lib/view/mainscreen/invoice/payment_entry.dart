import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/create_payment_entry_controller.dart';
import 'package:location_tracker_app/controller/customer_list_controller.dart';
import 'package:location_tracker_app/controller/mode_of_pay_controller.dart'; // Add this import
import 'package:location_tracker_app/controller/payment_entry_controller.dart';
import 'package:location_tracker_app/controller/payment_entry_draft_controller.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:location_tracker_app/modal/payment_entry_modal.dart';
import 'package:provider/provider.dart';

class PaymentEntryPage extends StatefulWidget {
  const PaymentEntryPage({super.key});

  @override
  _PaymentEntryPageState createState() => _PaymentEntryPageState();
}

class _PaymentEntryPageState extends State<PaymentEntryPage> {
  bool showAllocationWarning = false;
  MessageElement? selectedCustomer;
  PaymentEntryModal? paymentEntryData;
  TextEditingController paymentController = TextEditingController();
  Map<String, TextEditingController> invoiceControllers = {};
  Map<String, double> invoiceAllocations = {};
  double totalAllocated = 0.0;
  double advanceAmount = 0.0;
  bool isLoadingPaymentData = false;
  String selectedPaymentMethod = 'Cash';

  // ADD THESE NEW VARIABLES:
  TextEditingController referenceNumberController = TextEditingController();
  TextEditingController referenceDateController = TextEditingController();
  DateTime? selectedReferenceDate;

  @override
  void initState() {
    super.initState();
    paymentController.addListener(_calculateTotals);

    // Fetch customer list and payment methods on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GetCustomerListController>(
        context,
        listen: false,
      ).fetchCustomerList();

      // Fetch payment methods
      Provider.of<ModeOfPayController>(context, listen: false).fetchmodeofpay();
    });
  }

  @override
  void dispose() {
    paymentController.dispose();
    for (var controller in invoiceControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        selectedReferenceDate = picked;
        referenceDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _onCustomerSelected(MessageElement? customer) async {
    if (customer == null) return;

    setState(() {
      selectedCustomer = customer;
      paymentController.clear();
      invoiceAllocations.clear();
      isLoadingPaymentData = true;
      paymentEntryData = null;

      // Clear existing controllers
      for (var controller in invoiceControllers.values) {
        controller.dispose();
      }
      invoiceControllers.clear();

      totalAllocated = 0.0;
      advanceAmount = 0.0;
    });

    try {
      // Fetch payment entry data for selected customer
      final paymentController = Provider.of<PaymentEntryController>(
        context,
        listen: false,
      );
      final paymentdraftcontroller = Provider.of<PaymentEntryDraftController>(
        context,
        listen: false,
      );
      await paymentdraftcontroller.getPaymentEntryStatus(
        customerName: customer.name,
      );

      await paymentController.fetchPaymentEntry(customer: customer.name);

      setState(() {
        paymentEntryData = paymentController.paymentEntry;
        isLoadingPaymentData = false;

        // Initialize controllers for invoices
        if (paymentEntryData?.message.invoices != null) {
          for (var invoice in paymentEntryData!.message.invoices) {
            var controller = TextEditingController();
            controller.addListener(
              () => _onInvoiceAllocationChanged(invoice.invoiceName),
            );
            invoiceControllers[invoice.invoiceName] = controller;
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoadingPaymentData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load customer invoices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _hasTotalAllocationError() {
    final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
    return totalAllocated > paymentAmount;
  }

  void _showAllocationErrorSnackBar() {
    final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
    final excess = totalAllocated - paymentAmount;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Allocation Exceeds Payment Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Total: ${_formatCurrency(totalAllocated)} | Payment: ${_formatCurrency(paymentAmount)} | Excess: ${_formatCurrency(excess)}',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF764BA2),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Replace your _shouldEnableProcessButton method with this:

  // Replace your _shouldEnableProcessButton method with this simple version:

  bool _shouldEnableProcessButton() {
    final draftController = Provider.of<PaymentEntryDraftController>(
      context,
      listen: false,
    );

    // Check loading/error states
    // if (draftController.isLoading || draftController.errorMessage != null) {
    //   return false;
    // }

    // Check required fields
    if (selectedCustomer == null) return false;
    if (paymentEntryData == null) return false;
    if (isLoadingPaymentData) return false;

    // final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
    // if (paymentAmount <= 0) return false;

    // Check reference fields for non-cash payments
    // if (selectedPaymentMethod.toLowerCase() != 'cash') {
    //   if (referenceNumberController.text.trim().isEmpty) return false;
    //   if (selectedReferenceDate == null) return false;
    // }

    return true;
  }

  // Also, let's add a debug method to see what's happening:
  void _debugButtonState() {
    final draftController = Provider.of<PaymentEntryDraftController>(
      context,
      listen: false,
    );

    if (draftController.paymentEntryStatus?.message != null) {
      final message = draftController.paymentEntryStatus!.message;
    }
  }

  void _onInvoiceAllocationChanged(String invoiceId) {
    final controller = invoiceControllers[invoiceId];
    if (controller != null && paymentEntryData != null) {
      final value = double.tryParse(controller.text) ?? 0.0;

      setState(() {
        invoiceAllocations[invoiceId] = value; // Store actual entered value

        // Warning logic for first invoice allocation
        final firstInvoiceId = paymentEntryData!.message.invoices
            .where((inv) => inv.outstandingAmount > 0)
            .first
            .invoiceName;

        final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
        showAllocationWarning =
            invoiceId == firstInvoiceId &&
            value == paymentAmount &&
            paymentAmount > 0 &&
            paymentEntryData!.message.invoices
                    .where((inv) => inv.outstandingAmount > 0)
                    .length >
                1;
      });
    }
    _calculateTotals();
  }

  void _calculateTotals() {
    setState(() {
      totalAllocated = invoiceAllocations.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
      advanceAmount = paymentAmount > totalAllocated
          ? paymentAmount - totalAllocated
          : 0.0;
    });
  }

  void _clearAll() {
    setState(() {
      selectedCustomer = null;
      paymentEntryData = null;
      paymentController.clear();
      invoiceAllocations.clear();
      selectedPaymentMethod = 'Cash';
      showAllocationWarning = false; // ADD THIS LINE
      referenceNumberController.clear();
      referenceDateController.clear();
      selectedReferenceDate = null;

      for (var controller in invoiceControllers.values) {
        controller.dispose();
      }
      invoiceControllers.clear();

      totalAllocated = 0.0;
      advanceAmount = 0.0;
      isLoadingPaymentData = false;
    });
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
      case 'cheque':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'hi_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Consumer<ModeOfPayController>(
              builder: (context, modeController, _) {
                if (modeController.isLoading) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading payment methods...'),
                        ],
                      ),
                    ),
                  );
                }

                if (modeController.error != null) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 24),
                          SizedBox(height: 8),
                          Text(
                            'Error loading payment methods',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (modeController.modeofpay?.message == null) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'No payment methods available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                final availableMethods = modeController.modeofpay!.message
                    .where((e) => e.execute)
                    .map((e) => e.name)
                    .toList();

                if (availableMethods.isEmpty) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'No active payment methods available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                // Set default if current selection is not available
                if (!availableMethods.contains(selectedPaymentMethod)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      selectedPaymentMethod = availableMethods.first;
                    });
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Selection
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableMethods.map((method) {
                        final isSelected = selectedPaymentMethod == method;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPaymentMethod = method;
                              // Clear reference fields when switching payment methods
                              if (method.toLowerCase() == 'cash') {}
                            });
                          },
                          child: Container(
                            width: (MediaQuery.of(context).size.width / 3) - 20,
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purple
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPaymentIcon(method),
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  method,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.grey[600],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // ADD REFERENCE FIELDS FOR NON-CASH PAYMENTS
                    if (selectedPaymentMethod.toLowerCase() != 'cash') ...[
                      SizedBox(height: 20),
                      Divider(),
                      SizedBox(height: 16),

                      // Reference Number Field
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: Colors.purple,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reference Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      TextFormField(
                        controller: referenceNumberController,
                        decoration: InputDecoration(
                          labelText: 'Reference Number *',
                          hintText: 'Enter transaction/cheque number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: Icon(Icons.tag, size: 20),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Reference Date Field
                      TextFormField(
                        controller: referenceDateController,
                        readOnly: true,
                        onTap: _selectReferenceDate,
                        decoration: InputDecoration(
                          labelText: 'Reference Date *',
                          hintText: 'Select transaction date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Date: ${_formatDate(invoice.postingDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Due: ${_formatDate(invoice.dueDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Outstanding',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatCurrency(invoice.outstandingAmount.toDouble()),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Total Amount: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                _formatCurrency(invoice.grandTotal.toDouble()),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Payment Allocation: ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  // WRAP TextFormField in Column
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: invoiceControllers[invoice.invoiceName],
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        prefixText: '₹ ',
                      ),
                      enabled: paymentController.text.isNotEmpty,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 14),
                    ),
                    // ADD WARNING BELOW THE TEXTFIELD
                    Builder(
                      builder: (context) {
                        final enteredAmount =
                            double.tryParse(
                              invoiceControllers[invoice.invoiceName]?.text ??
                                  '',
                            ) ??
                            0.0;
                        final outstandingAmount = invoice.outstandingAmount
                            .toDouble();
                        final paymentAmount =
                            double.tryParse(paymentController.text) ?? 0.0;

                        // Show warning if entered amount > outstanding amount OR > payment amount
                        final showWarning =
                            enteredAmount > outstandingAmount ||
                            enteredAmount > paymentAmount;

                        if (!showWarning) return SizedBox.shrink();

                        String warningText = '';
                        if (enteredAmount > outstandingAmount &&
                            enteredAmount > paymentAmount) {
                          warningText =
                              'Amount exceeds both outstanding (${_formatCurrency(outstandingAmount)}) and payment amount (${_formatCurrency(paymentAmount)})';
                        } else if (enteredAmount > outstandingAmount) {
                          warningText =
                              'Amount exceeds outstanding amount (${_formatCurrency(outstandingAmount)})';
                        } else if (enteredAmount > paymentAmount) {
                          warningText =
                              'Amount exceeds payment amount (${_formatCurrency(paymentAmount)})';
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange[700],
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  warningText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show invoice items
          if (invoice.items.isNotEmpty) ...[
            SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Items (${invoice.items.length})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              children: invoice.items
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.itemName} (${item.itemCode})',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${item.qty} x ₹${item.rate} = ₹${item.amount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    if (selectedCustomer == null) return SizedBox.shrink();

    return Column(
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCustomer!.customerName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),

                // Customer basic info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Type:',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            selectedCustomer!.customerType,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedCustomer!.mobileNo != null &&
                        selectedCustomer!.mobileNo!.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile:',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              selectedCustomer!.mobileNo!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 8),

                // Additional customer info
                if (selectedCustomer!.emailId != null &&
                    selectedCustomer!.emailId!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.blue[600]),
                      SizedBox(width: 4),
                      Text(
                        selectedCustomer!.emailId!,
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ],

                if (selectedCustomer!.gstin != null &&
                    selectedCustomer!.gstin!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'GSTIN: ${selectedCustomer!.gstin!}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 12),

                // Payment entry data summary
                if (paymentEntryData != null) ...[
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Outstanding:',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                            Text(
                              _formatCurrency(
                                paymentEntryData!.message.totalOutstandingAmount
                                    .toDouble(),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Invoices:',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                            Text(
                              '${paymentEntryData!.message.invoices.where((invoice) => invoice.outstandingAmount != 0).length}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                if (isLoadingPaymentData) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading customer invoices...',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ADD THIS LINE - Draft Status Card
        _buildDraftStatusCard(),
      ],
    );
  }

  Widget _buildDraftStatusCard() {
    return Consumer<PaymentEntryDraftController>(
      builder: (context, draftController, child) {
        // Handle loading state
        if (draftController.isLoading) {
          return Card(
            color: Colors.orange[50],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Checking draft status...',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle error state
        if (draftController.errorMessage != null) {
          return SizedBox.shrink(); // Hide on error
        }

        // Check if there's draft data
        if (draftController.paymentEntryStatus?.message != null) {
          final message = draftController.paymentEntryStatus!.message;
          final allEntries = message.data;

          for (var entry in allEntries) {}

          // Separate draft and non-draft entries
          final draftEntries = allEntries
              .where((entry) => entry.status.toLowerCase() == 'draft')
              .toList();

          final nonDraftEntries = allEntries
              .where((entry) => entry.status.toLowerCase() != 'draft')
              .toList();

          // CASE 1: If any entry is Draft → Show "Waiting for Approval"
          if (draftEntries.isNotEmpty) {
            // Calculate allocated amount from all draft references
            double totalDraftAllocated = 0;
            for (var entry in draftEntries) {
              if (entry.references.isNotEmpty) {
                for (var ref in entry.references) {
                  totalDraftAllocated += ref.allocatedAmount ?? 0;
                }
              }
            }

            return Card(
              color: Color(0xFF764BA2).withOpacity(1),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waiting for Approval',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Total Allocated Amount: ${_formatCurrency(totalDraftAllocated)} pending approval',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // List each draft entry
                    ...draftEntries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 28),
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.amber[600],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.paymentEntry}: ${_formatCurrency(entry.references.fold<double>(0, (sum, ref) => sum + (ref.allocatedAmount ?? 0)))} - ${_formatDate(entry.postingDate)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // CASE 2: If no drafts but entries exist → Show non-draft entries
          if (nonDraftEntries.isNotEmpty) {
            return Card(
              color: Colors.grey[50],
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.grey[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Previous Payment Entries',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...nonDraftEntries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 28),
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.paymentEntry}: ${_formatCurrency(entry.paidAmount.toDouble())} - ${entry.status.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {}

        // Return empty widget if no relevant data
        return SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.payment),
            SizedBox(width: 8),
            Text('Payment Entry'),
          ],
        ),
        backgroundColor: Color(0xFF764BA2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Select Customer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Consumer<GetCustomerListController>(
                      builder: (context, controller, child) {
                        if (controller.isLoading) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading customers...'),
                                ],
                              ),
                            ),
                          );
                        }

                        if (controller.error != null) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Error: ${controller.error}',
                                      style: TextStyle(color: Colors.red),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (controller.customerlist?.message.message == null ||
                            controller.customerlist!.message.message.isEmpty) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                'No customers found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return DropdownSearch<MessageElement>(
                          items:
                              List<MessageElement>.from(
                                controller.customerlist!.message.message,
                              )..sort(
                                (a, b) => a.customerName
                                    .toLowerCase()
                                    .compareTo(b.customerName.toLowerCase()),
                              ),
                          selectedItem: selectedCustomer,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              hintText: 'Search customer...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          popupProps: PopupPropsMultiSelection.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Type to search...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            itemBuilder: (context, customer, isSelected) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    customer.customerName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(customer.customerName),
                                subtitle:
                                    customer.mobileNo != null &&
                                        customer.mobileNo!.isNotEmpty
                                    ? Text(customer.mobileNo!)
                                    : null,
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.1),
                              );
                            },
                          ),
                          itemAsString: (customer) => customer.customerName,
                          filterFn: (customer, filter) {
                            final searchLower = filter.toLowerCase();
                            return customer.customerName.toLowerCase().contains(
                                  searchLower,
                                ) ||
                                (customer.mobileNo?.toLowerCase().contains(
                                      searchLower,
                                    ) ??
                                    false);
                          },
                          onChanged: _onCustomerSelected,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (selectedCustomer != null) ...[
              SizedBox(height: 16),

              // Customer Summary with enhanced details
              _buildCustomerDetailsCard(),

              SizedBox(height: 16),

              // Payment Amount Entry
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Payment Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: paymentController,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter payment amount',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                              enabled:
                                  paymentEntryData != null &&
                                  !isLoadingPaymentData,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Payment Method Selection
              _buildPaymentMethodSelection(),

              SizedBox(height: 16),

              // Invoice List
              if (paymentEntryData != null && !isLoadingPaymentData) ...[
                paymentEntryData?.message.totalOutstandingAmount == 0
                    ? SizedBox()
                    : Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Outstanding Invoices',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ...paymentEntryData!.message.invoices
                                  .where(
                                    (invoice) => invoice.outstandingAmount != 0,
                                  )
                                  .map((invoice) => _buildInvoiceCard(invoice)),

                              // Payment Summary
                              Card(
                                color: Colors.grey[50],
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payment Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (showAllocationWarning) ...[
                                        SizedBox(height: 12),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            border: Border.all(
                                              color: Colors.amber[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber,
                                                color: Colors.amber[800],
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'You have allocated the full payment amount to the first invoice. Consider distributing across multiple invoices if needed.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.amber[800],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Total Allocated',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  _formatCurrency(
                                                    totalAllocated,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Payment Method',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      _getPaymentIcon(
                                                        selectedPaymentMethod,
                                                      ),
                                                      size: 16,
                                                      color: Colors.purple,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      selectedPaymentMethod,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.purple,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Advance Amount',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  _formatCurrency(
                                                    advanceAmount,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: advanceAmount > 0
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (advanceAmount > 0) ...[
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Extra payment of ${_formatCurrency(advanceAmount)} will be treated as advance.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAll,
                      child: Text('Clear All'),
                    ),
                  ),

                  SizedBox(width: 16),
                  Expanded(
                    child: Consumer<PaymentEntryDraftController>(
                      // Add Consumer here
                      builder: (context, draftController, child) {
                        return ElevatedButton(
                          onPressed: _getButtonPressedState(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Consumer<CraetePaymentEntryController>(
                            builder: (context, controller, child) {
                              return controller.isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('Process Payment');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  VoidCallback? _getButtonPressedState() {
    // Add debug call to see what's happening
    _debugButtonState();

    // Check all conditions individually for better debugging
    if (paymentController.text.isEmpty) {
      return null;
    }

    final paymentAmount = double.tryParse(paymentController.text) ?? 0.0;
    if (paymentAmount <= 0) {
      return null;
    }

    if (isLoadingPaymentData) {
      return null;
    }

    if (paymentEntryData == null) {
      return null;
    }

    if (selectedCustomer == null) {
      return null;
    }

    if (!_shouldEnableProcessButton()) {
      return null;
    }

    // Return the actual function to execute when button is pressed
    return () async {
      // Enhanced validation
      if (_hasTotalAllocationError()) {
        _showAllocationErrorSnackBar();
        return;
      }

      // Check for non-cash payment method requirements
      if (selectedPaymentMethod.toLowerCase() != 'cash') {
        String refNo = referenceNumberController.text.trim();
        if (refNo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reference number is required for $selectedPaymentMethod',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (selectedReferenceDate == null ||
            referenceDateController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reference date is required for $selectedPaymentMethod',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final controller = context.read<CraetePaymentEntryController>();

      // Prepare invoice allocations
      List<Map<String, dynamic>> allocations = [];
      invoiceAllocations.forEach((invoiceId, amount) {
        if (amount > 0) {
          allocations.add({"invoice": invoiceId, "amount": amount});
        }
      });

      try {
        await controller.createPayment(
          customer: selectedCustomer!.name,
          totalAllocatedAmount: paymentAmount,
          modeOfPayment: selectedPaymentMethod,
          invoiceAllocations: allocations,
          referenceNumber: selectedPaymentMethod.toLowerCase() != 'cash'
              ? referenceNumberController.text.trim()
              : null,
          referenceDate:
              selectedPaymentMethod.toLowerCase() != 'cash' &&
                  selectedReferenceDate != null
              ? DateFormat('yyyy-MM-dd').format(selectedReferenceDate!)
              : null,
        );

        if (controller.responseData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Entry Created Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearAll();
        } else if (controller.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${controller.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }
}

// Simple app to run the payment entry
