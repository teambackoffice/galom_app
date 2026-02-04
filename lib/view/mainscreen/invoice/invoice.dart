import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/invoice_list_controller.dart';
import 'package:location_tracker_app/modal/invoice_list_modal.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/invoice_details.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/payment_entry.dart'
    hide Invoice;
import 'package:location_tracker_app/view/mainscreen/invoice/payment_page.dart'
    hide Invoice;
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
      Provider.of<InvoiceListController>(
        context,
        listen: false,
      ).fetchInvoiceList();
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

  // Manual refresh button handler
  void _manualRefresh() {
    _refreshIndicatorKey.currentState?.show();
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

                      final allInvoices =
                          controller.invoiceList?.message.invoices ?? [];
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
                                itemCount: filteredInvoices.length,
                                itemBuilder: (context, index) {
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
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                    colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
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
