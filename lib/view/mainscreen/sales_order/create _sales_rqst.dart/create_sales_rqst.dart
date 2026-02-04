import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/create_sales_return_contoller.dart';
import 'package:location_tracker_app/controller/customer_list_controller.dart';
import 'package:location_tracker_app/controller/item_list_controller.dart';
import 'package:location_tracker_app/controller/sales_invoice_details_controller.dart';
import 'package:location_tracker_app/controller/sales_invoice_id_controller.dart';
import 'package:location_tracker_app/controller/sales_return_controller.dart';
import 'package:location_tracker_app/modal/sales_invoice_id_modal.dart';
import 'package:provider/provider.dart';

class CreateSalesReturnPage extends StatefulWidget {
  const CreateSalesReturnPage({super.key});

  @override
  State<CreateSalesReturnPage> createState() => _CreateSalesReturnPageState();
}

class _CreateSalesReturnPageState extends State<CreateSalesReturnPage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNameController = TextEditingController();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _buyingDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerController = TextEditingController();

  DateTime? _selectedBuyingDate;
  String? _selectedInvoiceId;
  final Map<String, int> _selectedItems = {}; // item_code -> return_quantity
  final Map<String, double> _selectedItemRates = {}; // item_code -> rate
  String _invoiceSearchQuery = "";
  String _itemSearchQuery = "";
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _customerSearchQuery;

  // New: Creation mode toggle
  bool _isInvoiceMode = true; // true = with invoice, false = without invoice

  final List<String> _returnReasons = [
    'Damaged Product',
    'Wrong Product Delivered',
    'Quality Issue',
    'Size Mismatch',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    // Load invoice IDs, items, and customers when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesInvoiceIdsController>(
        context,
        listen: false,
      ).getSalesInvoiceIds();
      Provider.of<ItemListController>(context, listen: false).fetchItemList();
      Provider.of<GetCustomerListController>(
        context,
        listen: false,
      ).fetchCustomerList();
    });
  }

  @override
  void dispose() {
    _invoiceNameController.dispose();
    _productNameController.dispose();
    _qtyController.dispose();
    _buyingDateController.dispose();
    _notesController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectBuyingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBuyingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF764BA2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBuyingDate) {
      setState(() {
        _selectedBuyingDate = picked;
        _buyingDateController.text = _formatDate(picked);
      });
    }
  }

  // Toggle between creation modes
  void _toggleCreationMode(bool isInvoiceMode) {
    setState(() {
      _isInvoiceMode = isInvoiceMode;
      _selectedItems.clear();
      _selectedItemRates.clear();
      _selectedInvoiceId = null;
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _invoiceNameController.clear();
      _customerController.clear();
      _buyingDateController.clear();
      _selectedBuyingDate = null;
    });
  }

  // Method to handle invoice selection and fetch details
  void _onInvoiceSelected(String invoiceId) async {
    setState(() {
      _selectedInvoiceId = invoiceId;
      _invoiceNameController.text = invoiceId;
      _selectedItems.clear();
      _selectedItemRates.clear();
      _productNameController.clear();
      _qtyController.clear();
      _buyingDateController.clear();
      _selectedBuyingDate = null;
    });

    final detailController = Provider.of<SalesInvoiceDetailController>(
      context,
      listen: false,
    );
    await detailController.getSalesInvoiceDetail(invoiceId: invoiceId);

    if (detailController.salesInvoiceDetail != null) {
      final postingDate =
          detailController.salesInvoiceDetail!.message.data.postingDate;
      setState(() {
        _selectedBuyingDate = postingDate;
        _buyingDateController.text = _formatDate(postingDate);
      });
    }

    Navigator.pop(context);
  }

  // Method to handle direct item selection
  void _onDirectItemSelected(dynamic item) {
    final itemCode = item.itemCode;
    final rate = item.price;

    setState(() {
      if (_selectedItems.containsKey(itemCode)) {
        _selectedItems.remove(itemCode);
        _selectedItemRates.remove(itemCode);
      } else {
        _selectedItems[itemCode] = 1;
        _selectedItemRates[itemCode] = rate;
      }
    });

    Navigator.pop(context);
  }

  // Method to handle customer selection
  void _onCustomerSelected(dynamic customer) {
    setState(() {
      _selectedCustomerId = customer.name;
      _selectedCustomerName = customer.customerName;
      _customerController.text = customer.customerName;
    });

    Navigator.pop(context);
  }

  // Helper method to highlight search text (reused from original)
  List<TextSpan> _highlightSearchText(
    String text,
    String query,
    bool isSelected,
  ) {
    if (query.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF764BA2)
                : const Color(0xFF2C3E50),
          ),
        ),
      ];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index >= 0) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF764BA2)
                  : const Color(0xFF2C3E50),
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF764BA2)
                : const Color(0xFF2C3E50),
            backgroundColor: Colors.yellow[200],
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF764BA2)
                : const Color(0xFF2C3E50),
          ),
        ),
      );
    }

    return spans;
  }

  // Method to show invoice selection bottom sheet (updated to show customer names)
  void _showInvoiceSelectionSheet() {
    _invoiceSearchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<SalesInvoiceIdsController>(
          builder: (context, invoiceController, child) {
            List<SalesInvoiceData> filteredInvoices = [];
            if (invoiceController.salesInvoiceIds?.invoices != null) {
              final searchQuery = _invoiceSearchQuery.toLowerCase().trim();
              filteredInvoices = invoiceController.salesInvoiceIds!.invoices
                  .where((invoice) {
                    if (searchQuery.isEmpty) return true;

                    // Search in invoice name
                    if (invoice.name.toLowerCase().contains(searchQuery)) {
                      return true;
                    }

                    // Search in customer name
                    if (invoice.customer.toLowerCase().contains(searchQuery)) {
                      return true;
                    }

                    // Search in outstanding amount (if searching for numbers)
                    if (invoice.outstandingAmount.toString().contains(
                      searchQuery,
                    )) {
                      return true;
                    }

                    return false;
                  })
                  .toList();

              // Sort results: exact matches first, then partial matches
              filteredInvoices.sort((a, b) {
                final aInvoiceExact = a.name.toLowerCase() == searchQuery;
                final bInvoiceExact = b.name.toLowerCase() == searchQuery;
                final aCustomerExact = a.customer.toLowerCase() == searchQuery;
                final bCustomerExact = b.customer.toLowerCase() == searchQuery;

                if (aInvoiceExact && !bInvoiceExact) return -1;
                if (!aInvoiceExact && bInvoiceExact) return 1;
                if (aCustomerExact && !bCustomerExact) return -1;
                if (!aCustomerExact && bCustomerExact) return 1;

                // If both are partial matches, sort by invoice name
                return a.name.compareTo(b.name);
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF764BA2),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Invoice',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (invoiceController.salesInvoiceIds?.invoices !=
                                  null)
                                Text(
                                  '${filteredInvoices.length} of ${invoiceController.salesInvoiceIds!.invoices.length} invoices',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          _invoiceSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by invoice name, customer',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF764BA2),
                        ),
                        suffixIcon: _invoiceSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() {
                                    _invoiceSearchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF764BA2),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: invoiceController.isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF764BA2),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading invoices...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredInvoices.isEmpty &&
                              _invoiceSearchQuery.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No invoices found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search terms',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = filteredInvoices[index];
                              final isSelected =
                                  _selectedInvoiceId == invoice.name;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF764BA2)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? const Color(0xFF764BA2).withOpacity(0.1)
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF764BA2)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.receipt,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: RichText(
                                    text: TextSpan(
                                      children: _highlightSearchText(
                                        invoice.name,
                                        _invoiceSearchQuery,
                                        isSelected,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Customer: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            ...(_highlightSearchText(
                                              invoice.customer,
                                              _invoiceSearchQuery,
                                              false,
                                            ).map(
                                              (span) => TextSpan(
                                                text: span.text,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight:
                                                      span.style?.fontWeight ??
                                                      FontWeight.normal,
                                                  backgroundColor: span
                                                      .style
                                                      ?.backgroundColor,
                                                ),
                                              ),
                                            )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF764BA2),
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () => _onInvoiceSelected(invoice.name),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // New method to show customer selection sheet
  void _showCustomerSelectionSheet() {
    _customerSearchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<GetCustomerListController>(
          builder: (context, customerController, child) {
            List<dynamic> filteredCustomers = [];
            if (customerController.customerlist?.message.message != null) {
              filteredCustomers = customerController
                  .customerlist!
                  .message
                  .message
                  .where(
                    (customer) =>
                        customer.customerName.toLowerCase().contains(
                          _customerSearchQuery!.toLowerCase(),
                        ) ||
                        customer.name.toLowerCase().contains(
                          _customerSearchQuery!.toLowerCase(),
                        ) ||
                        (customer.mobileNo?.toLowerCase().contains(
                              _customerSearchQuery!.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF764BA2),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Customer',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (customerController
                                      .customerlist
                                      ?.message
                                      .message !=
                                  null)
                                Text(
                                  '${filteredCustomers.length} of ${customerController.customerlist!.message.message.length} customers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          _customerSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF764BA2),
                        ),
                        suffixIcon: _customerSearchQuery!.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() {
                                    _customerSearchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF764BA2),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: customerController.isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF764BA2),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading customers...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : customerController.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading customers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  customerController.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    customerController.fetchCustomerList();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF764BA2),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredCustomers.isEmpty &&
                              _customerSearchQuery!.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No customers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search terms',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final isSelected =
                                  _selectedCustomerId == customer.name;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF764BA2)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? const Color(0xFF764BA2).withOpacity(0.1)
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF764BA2)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: RichText(
                                    text: TextSpan(
                                      children: _highlightSearchText(
                                        customer.customerName,
                                        _customerSearchQuery!,
                                        isSelected,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID: ${customer.name}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF764BA2),
                                          size: 24,
                                        )
                                      : null,
                                  onTap: () => _onCustomerSelected(customer),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDirectItemSelectionSheet() {
    _itemSearchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<ItemListController>(
          builder: (context, itemController, child) {
            List<dynamic> filteredItems = [];
            if (itemController.itemlist?.message != null) {
              filteredItems = itemController.itemlist!.message
                  .where(
                    (item) =>
                        item.itemName.toLowerCase().contains(
                          _itemSearchQuery.toLowerCase(),
                        ) ||
                        item.itemCode.toLowerCase().contains(
                          _itemSearchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Color(0xFF764BA2),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Items',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (itemController.itemlist?.message != null)
                                Text(
                                  '${filteredItems.length} of ${itemController.itemlist!.message.length} items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          _itemSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF764BA2),
                        ),
                        suffixIcon: _itemSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() {
                                    _itemSearchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF764BA2),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: itemController.isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF764BA2),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading items...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredItems.isEmpty && _itemSearchQuery.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No items found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search terms',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = _selectedItems.containsKey(
                                item.itemCode,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF764BA2)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? const Color(0xFF764BA2).withOpacity(0.1)
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF764BA2)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: RichText(
                                    text: TextSpan(
                                      children: _highlightSearchText(
                                        item.itemName,
                                        _itemSearchQuery,
                                        isSelected,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Code: ${item.itemCode}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Rate: ₹${item.price} | UOM: ${item.uom}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF764BA2),
                                          size: 24,
                                        )
                                      : const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                  onTap: () => _onDirectItemSelected(item),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Updated method to build creation mode toggle
  Widget _buildCreationModeToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Creation Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleCreationMode(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _isInvoiceMode
                          ? const Color(0xFF764BA2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isInvoiceMode
                            ? const Color(0xFF764BA2)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: _isInvoiceMode
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'With Invoice',
                          style: TextStyle(
                            color: _isInvoiceMode
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleCreationMode(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: !_isInvoiceMode
                          ? const Color(0xFF764BA2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isInvoiceMode
                            ? const Color(0xFF764BA2)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: !_isInvoiceMode
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Direct Items',
                          style: TextStyle(
                            color: !_isInvoiceMode
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isInvoiceMode
                ? 'Create return based on an existing invoice'
                : 'Create return by selecting items directly',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Widget to build invoice items section (original method)
  Widget _buildInvoiceItemsSection() {
    if (!_isInvoiceMode) return const SizedBox.shrink();

    return Consumer<SalesInvoiceDetailController>(
      builder: (context, controller, child) {
        if (_selectedInvoiceId == null) {
          return const SizedBox.shrink();
        }

        if (controller.isLoading) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF764BA2)),
                  SizedBox(height: 16),
                  Text(
                    'Loading invoice items...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.errorMessage != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.getSalesInvoiceDetail(
                      invoiceId: _selectedInvoiceId!,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF764BA2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.salesInvoiceDetail == null) {
          return const SizedBox.shrink();
        }

        final items = controller.salesInvoiceDetail!.message.data.items;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF764BA2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Invoice Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Select items and quantities to return:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _buildInvoiceItemTile(item)),
            ],
          ),
        );
      },
    );
  }

  // Widget to build direct items selection section
  Widget _buildDirectItemsSection() {
    if (_isInvoiceMode || _selectedItems.isEmpty)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF764BA2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Selected Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showDirectItemSelectionSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add More'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF764BA2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Adjust quantities for selected items:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Consumer<ItemListController>(
            builder: (context, itemController, child) {
              if (itemController.itemlist?.message == null) {
                return const SizedBox.shrink();
              }

              final selectedItemsList = itemController.itemlist!.message
                  .where((item) => _selectedItems.containsKey(item.itemCode))
                  .toList();

              return Column(
                children: selectedItemsList
                    .map((item) => _buildDirectItemTile(item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget to build individual invoice item tile (original method with slight modifications)
  Widget _buildInvoiceItemTile(dynamic item) {
    final itemCode = item.itemCode;
    final itemName = item.itemName;
    final maxQty = item.qty;
    final rate = item.rate;
    final isSelected = _selectedItems.containsKey(itemCode);
    final returnQty = _selectedItems[itemCode] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF764BA2) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? const Color(0xFF764BA2).withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF764BA2)
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: $itemCode',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: $maxQty • Rate: ₹$rate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems[itemCode] = 1;
                        _selectedItemRates[itemCode] = rate;
                      } else {
                        _selectedItems.remove(itemCode);
                        _selectedItemRates.remove(itemCode);
                      }
                    });
                  },
                  activeColor: const Color(0xFF764BA2),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Return Quantity:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: returnQty > 1
                              ? () {
                                  setState(() {
                                    _selectedItems[itemCode] = returnQty - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: const Color(0xFF764BA2),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            returnQty.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: returnQty < maxQty
                              ? () {
                                  setState(() {
                                    _selectedItems[itemCode] = returnQty + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: const Color(0xFF764BA2),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
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

  // Widget to build individual direct item tile
  Widget _buildDirectItemTile(dynamic item) {
    final itemCode = item.itemCode;
    final itemName = item.itemName;
    final rate = item.price;
    final returnQty = _selectedItems[itemCode] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF764BA2), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF764BA2).withOpacity(0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF764BA2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: $itemCode',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rate: ₹$rate | UOM: ${item.uom}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedItems.remove(itemCode);
                      _selectedItemRates.remove(itemCode);
                    });
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[600],
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Return Quantity:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: returnQty > 1
                            ? () {
                                setState(() {
                                  _selectedItems[itemCode] = returnQty - 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: const Color(0xFF764BA2),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          returnQty.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedItems[itemCode] = returnQty + 1;
                          });
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: const Color(0xFF764BA2),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one item to return'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final controller = Provider.of<CreateSalesReturnController>(
        context,
        listen: false,
      );

      String customer = '';
      List<Map<String, dynamic>> items = [];

      if (_isInvoiceMode) {
        // Invoice mode - get customer from invoice details
        final detailController = Provider.of<SalesInvoiceDetailController>(
          context,
          listen: false,
        );

        customer = detailController.salesInvoiceDetail!.message.data.customer;

        items = _selectedItems.entries.map((entry) {
          final item = detailController.salesInvoiceDetail!.message.data.items
              .firstWhere((i) => i.itemCode == entry.key);

          return {
            "item_code": item.itemCode,
            "qty": entry.value,
            "rate": item.rate,
          };
        }).toList();
      } else {
        // Direct mode - use selected customer and item rates
        customer = _selectedCustomerId ?? _customerController.text;

        final itemController = Provider.of<ItemListController>(
          context,
          listen: false,
        );

        items = _selectedItems.entries.map((entry) {
          final item = itemController.itemlist!.message.firstWhere(
            (i) => i.itemCode == entry.key,
          );

          return {
            "item_code": item.itemCode,
            "qty": entry.value,
            "rate": item.price,
          };
        }).toList();
      }

      await controller.createSalesReturn(
        returnAgainst: _isInvoiceMode ? _invoiceNameController.text : "",
        returnDate: _buyingDateController.text,
        customer: customer,

        buyingDate: _buyingDateController.text,
        return_reason: _notesController.text,
        items: items,
      );

      if (controller.errorMessage != null) {
        _showErrorDialog(controller.errorMessage!);
        return;
      }

      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sales return has been created successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Provider.of<SalesReturnController>(
                        context,
                        listen: false,
                      ).fetchsalesreturn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF764BA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error,
                    color: Colors.red.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Error!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF764BA2),
                          side: const BorderSide(color: Color(0xFF764BA2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF764BA2)),
            suffixIcon: onTap != null
                ? Icon(
                    readOnly ? Icons.arrow_drop_down : Icons.edit,
                    color: const Color(0xFF764BA2),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF764BA2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Sales Return"),
        backgroundColor: const Color(0xFF764BA2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF764BA2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.assignment_return,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Sales Return',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose your preferred creation method',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Creation Mode Toggle
              _buildCreationModeToggle(),

              const SizedBox(height: 24),

              // Invoice Selection or Direct Item Selection
              if (_isInvoiceMode) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildTextField(
                    controller: _invoiceNameController,
                    label: 'Invoice Name',
                    hint: 'Select an invoice',
                    icon: Icons.receipt_long,
                    readOnly: true,
                    onTap: _showInvoiceSelectionSheet,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an invoice';
                      }
                      return null;
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _customerController,
                        label: 'Customer',
                        hint: 'Select a customer',
                        icon: Icons.person,
                        readOnly: true,
                        onTap: _showCustomerSelectionSheet,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a customer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showDirectItemSelectionSheet,
                              icon: const Icon(Icons.add),
                              label: Text(
                                _selectedItems.isEmpty
                                    ? 'Select Items'
                                    : 'Add Items (${_selectedItems.length} selected)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF764BA2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Items Section (shows different content based on mode)
              _buildInvoiceItemsSection(),
              _buildDirectItemsSection(),

              // Add spacing if items are shown
              if ((_isInvoiceMode && _selectedInvoiceId != null) ||
                  (!_isInvoiceMode && _selectedItems.isNotEmpty))
                const SizedBox(height: 24),

              // Form Fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _buyingDateController,
                      label: _isInvoiceMode ? 'Purchase Date' : 'Return Date',
                      hint: _isInvoiceMode
                          ? 'Will be auto-filled from selected invoice'
                          : 'Select return date',
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _isInvoiceMode ? null : _selectBuyingDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _isInvoiceMode
                              ? 'Purchase date will be set when you select an invoice'
                              : 'Please select a return date';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hint: 'Enter additional notes (optional)',
                      icon: Icons.note_alt,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button with Loading State
              Consumer<CreateSalesReturnController>(
                builder: (context, controller, child) {
                  return ElevatedButton(
                    onPressed: controller.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isLoading
                          ? Colors.grey[400]
                          : const Color(0xFF764BA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: controller.isLoading ? 0 : 2,
                    ),
                    child: controller.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating Sales Return...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Sales Return ${_selectedItems.isNotEmpty ? '(${_selectedItems.length} items)' : ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
