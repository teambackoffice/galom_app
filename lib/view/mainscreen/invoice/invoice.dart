import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/invoice_list_controller.dart';
import 'package:location_tracker_app/controller/my_target_controller.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/invoice_details.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/payment_entry.dart'
    hide Invoice;
import 'package:location_tracker_app/view/mainscreen/invoice/payment_page.dart'
    hide Invoice;
import 'package:location_tracker_app/view/mainscreen/target/my_target.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invoiceController = Provider.of<InvoiceListController>(
        context,
        listen: false,
      );
      invoiceController.fetchInvoiceList();
      invoiceController.fetchCustomers();
      Provider.of<MyTargetController>(
        context,
        listen: false,
      ).fetchCurrentMonthSummary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter invoices based on search query
  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    if (_searchQuery.isEmpty) {
      return invoices;
    }

    return invoices.where((invoice) {
      final invoiceId = invoice.invoiceId.toLowerCase();
      final customer = invoice.customer.toLowerCase();
      final query = _searchQuery.toLowerCase();

      return invoiceId.contains(query) || customer.contains(query);
    }).toList();
  }

  // Clear search
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearchExpanded = false;
    });
  }

  // Refresh function
  Future<void> _onRefresh() async {
    try {
      Provider.of<MyTargetController>(
        context,
        listen: false,
      ).fetchCurrentMonthSummary();
      await Provider.of<InvoiceListController>(
        context,
        listen: false,
      ).fetchInvoiceList();
    } catch (error) {
      // Handle error if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh invoices'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _makePayment(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          invoice: invoice,
          onPaymentSuccess: (amount, method) {
            setState(() {
              invoice.status = "Paid";
              print("Paid Amount: $amount, Method: $method");
            });
            // Refresh the list after successful payment
            _onRefresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F6FA), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterBar(),
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _onRefresh,
                  color: Color(0xFF667EEA),
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  child: Consumer<InvoiceListController>(
                    builder: (context, controller, child) {
                      if (controller.isLoading) {
                        return _buildShimmerList();
                      }

                      if (controller.invoiceList == null ||
                          controller.invoiceList!.message.invoices.isEmpty) {
                        return _buildEmptyState();
                      }

                      final customer = controller.selectedCustomer;
                      final allInvoices =
                          (controller.invoiceList?.message.invoices ?? [])
                              .where(
                                (invoice) =>
                                    customer == null ||
                                    invoice.customer == customer.name,
                              )
                              .toList();
                      final filteredInvoices = _filterInvoices(allInvoices);

                      // Show no results found if search query exists but no matches
                      if (_searchQuery.isNotEmpty && filteredInvoices.isEmpty) {
                        return _buildNoResultsState();
                      }

                      return Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Show search results count
                            if (_searchQuery.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      '${filteredInvoices.length} result${filteredInvoices.length != 1 ? 's' : ''} found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                physics: AlwaysScrollableScrollPhysics(),
                                // Target overview sits above the invoices,
                                // hidden while searching.
                                itemCount:
                                    filteredInvoices.length +
                                    (_searchQuery.isEmpty ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_searchQuery.isEmpty) {
                                    if (index == 0) {
                                      return const InvoiceTargetSection();
                                    }
                                    index -= 1;
                                  }
                                  final invoice = filteredInvoices[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              InvoiceDetails(invoice: invoice),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.all(20),
                                        leading: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: invoice.status == "Paid"
                                                ? Color(
                                                    0xFF10B981,
                                                  ).withOpacity(0.1)
                                                : Color(
                                                    0xFFF59E0B,
                                                  ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            invoice.status == "Paid"
                                                ? Icons.check_circle_rounded
                                                : Icons.schedule_rounded,
                                            color: invoice.status == "Paid"
                                                ? Color(0xFF10B981)
                                                : Color(0xFFF59E0B),
                                            size: 28,
                                          ),
                                        ),
                                        title: _buildHighlightedText(
                                          invoice.invoiceId,
                                          _searchQuery,
                                          TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 4),
                                            _buildHighlightedText(
                                              invoice.customer,
                                              _searchQuery,
                                              TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total: ₹${invoice.grandTotal.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                                Text(
                                                  'Due: ₹${invoice.outstandingAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: _buildTrailingWidget(invoice),
                                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build search bar widget
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isSearchExpanded ? 80 : 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by invoice ID or customer...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Month filter is applied on the server, customer filter locally
  Widget _buildFilterBar() {
    return Consumer<InvoiceListController>(
      builder: (context, controller, child) {
        final month = controller.selectedMonth;
        final customer = controller.selectedCustomer;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  icon: Icons.calendar_month_rounded,
                  label: month == null
                      ? 'All months'
                      : DateFormat('MMM yyyy').format(month),
                  isActive: month != null,
                  onTap: () => _pickMonth(controller),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  icon: Icons.person_rounded,
                  label: customer?.customerName ?? 'All customers',
                  isActive: customer != null,
                  onTap: () => _pickCustomer(controller),
                ),
              ),
              if (month != null || customer != null) ...[
                SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: controller.clearFilters,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      Icons.filter_alt_off_rounded,
                      size: 18,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? Color(0xFF667EEA) : Colors.grey[700]!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF667EEA).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Color(0xFF667EEA) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(InvoiceListController controller) async {
    // Current month and the 23 before it
    final now = DateTime.now();
    final months = List.generate(24, (i) => DateTime(now.year, now.month - i));
    final selected = controller.selectedMonth;

    final picked = await _showFilterSheet<DateTime>(
      title: 'Select month',
      allLabel: 'All months',
      options: months,
      labelOf: (m) => DateFormat('MMMM yyyy').format(m),
      isSelected: (m) =>
          selected != null &&
          m.year == selected.year &&
          m.month == selected.month,
      isAllSelected: selected == null,
    );
    if (picked != null) {
      controller.setMonth(picked.value);
    }
  }

  Future<void> _pickCustomer(InvoiceListController controller) async {
    if (controller.customers.isEmpty) {
      await controller.fetchCustomers();
    }
    if (!mounted) return;
    final selected = controller.selectedCustomer;

    final picked = await _showFilterSheet<MessageElement>(
      title: 'Select customer',
      allLabel: 'All customers',
      options: controller.customers,
      labelOf: (c) => c.customerName,
      isSelected: (c) => c.name == selected?.name,
      isAllSelected: selected == null,
      searchHint: 'Search customer...',
      matches: (c, query) =>
          c.customerName.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query),
    );
    if (picked != null) {
      controller.setCustomer(picked.value);
    }
  }

  // Returns null when dismissed; a _FilterChoice with a null value for "All".
  // Passing [matches] adds a search bar; it receives the lowercased query.
  Future<_FilterChoice<T>?> _showFilterSheet<T>({
    required String title,
    required String allLabel,
    required List<T> options,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required bool isAllSelected,
    String searchHint = 'Search...',
    bool Function(T option, String query)? matches,
  }) {
    Widget tile(String label, bool selected, _FilterChoice<T> choice) {
      return ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Color(0xFF667EEA) : Colors.black87,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_rounded, color: Color(0xFF667EEA))
            : null,
        onTap: () => Navigator.pop(context, choice),
      );
    }

    String query = '';

    return showModalBottomSheet<_FilterChoice<T>>(
      context: context,
      isScrollControlled: matches != null,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = query.isEmpty || matches == null
              ? options
              : options.where((o) => matches(o, query)).toList();
          return Padding(
            // Keep the search bar above the keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      (matches != null ? 0.8 : 0.6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (matches != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          onChanged: (value) => setSheetState(
                            () => query = value.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: searchHint,
                            prefixIcon: Icon(Icons.search_rounded),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (query.isEmpty)
                            tile(
                              allLabel,
                              isAllSelected,
                              _FilterChoice<T>(null),
                            ),
                          for (final option in visible)
                            tile(
                              labelOf(option),
                              isSelected(option),
                              _FilterChoice<T>(option),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build highlighted text for search results
  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    // Determine the appropriate text color
    Color textColor = style.color ?? Colors.black87;

    return RichText(
      text: TextSpan(
        style: style.copyWith(color: textColor),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: Color(
                0xFFFFEB3B,
              ).withOpacity(0.4), // Changed to yellow
              color: Colors.black87, // Explicit black text for highlighted part
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "No Results Found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Try searching with different keywords",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _clearSearch,
                child: Text(
                  "Clear Search",
                  style: TextStyle(color: Color(0xFF667EEA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity * 0.6,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity * 0.4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity * 0.5,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: double.infinity * 0.45,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [const InvoiceTargetSection(), _buildEmptyMessage()],
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return SizedBox(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "No Invoices Found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Pull down to refresh",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(Invoice invoice) {
    bool isFullyPaid = invoice.outstandingAmount == 0;
    //  &&
    // invoice.payments.isNotEmpty &&
    // invoice.payments.every((payment) => payment.status == "Submitted");

    bool hasDraftedPayment = invoice.payments.any(
      (payment) => payment.status == "Draft",
    );

    if (isFullyPaid) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'PAID',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    } else if (hasDraftedPayment == true) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          'Submitted',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _makePayment(invoice),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF667EEA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF764BA2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.receipt, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Invoices',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),

              // Search button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (!_isSearchExpanded) {
                      _clearSearch();
                    }
                  });
                },
                icon: Icon(
                  _isSearchExpanded ? Icons.close : Icons.search,
                  color: Colors.black,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Manual refresh button
              PopupMenuButton(
                icon: Icon(Icons.filter_list, color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentEntryPage(),
                      ),
                    );
                  });
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'Payment Entry',
                      child: Text('Payment Entry'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChoice<T> {
  final T? value;
  const _FilterChoice(this.value);
}
