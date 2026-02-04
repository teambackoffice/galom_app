import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/sales_return_controller.dart';
import 'package:location_tracker_app/view/mainscreen/sales_order/create%20_sales_rqst.dart/create_sales_rqst.dart';
import 'package:provider/provider.dart';

class SalesReturnListPage extends StatefulWidget {
  const SalesReturnListPage({super.key});

  @override
  _SalesReturnListPageState createState() => _SalesReturnListPageState();
}

class _SalesReturnListPageState extends State<SalesReturnListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesReturnController>(
        context,
        listen: false,
      ).fetchsalesreturn();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter function for search
  List<dynamic> _filterSalesReturns(List<dynamic> salesReturns) {
    if (_searchQuery.isEmpty) {
      return salesReturns;
    }

    return salesReturns.where((data) {
      final invoiceId = (data.name ?? '').toLowerCase();
      final customer = (data.customer ?? '').toLowerCase();
      final returnAgainst = (data.returnAgainst ?? '').toLowerCase();
      final salesPerson = (data.customSalesPerson ?? '').toLowerCase();

      return invoiceId.contains(_searchQuery) ||
          customer.contains(_searchQuery) ||
          returnAgainst.contains(_searchQuery) ||
          salesPerson.contains(_searchQuery);
    }).toList();
  }

  // Refresh function
  Future<void> _onRefresh() async {
    final controller = Provider.of<SalesReturnController>(
      context,
      listen: false,
    );
    await controller.fetchsalesreturn();
  }

  Color _getStatusColor(String? workflowState) {
    if (workflowState == null) return const Color(0xFF95A5A6);
    final lowerState = workflowState.toLowerCase();
    if (lowerState.contains('pending')) {
      return const Color(0xFFF39C12);
    } else if (lowerState.contains('approved')) {
      return const Color(0xFF27AE60);
    } else if (lowerState.contains('rejected')) {
      return const Color(0xFFE74C3C);
    }
    return const Color(0xFF764BA2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: _isSearchVisible ? 140 : 80,
        title: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
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
                          'Sales Returns',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search toggle button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                        if (!_isSearchVisible) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: Icon(
                      _isSearchVisible ? Icons.close : Icons.search,
                      color: const Color(0xFF764BA2),
                      size: 28,
                    ),
                  ),
                ],
              ),
              // Search bar
              if (_isSearchVisible) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText:
                          'Search by Invoice ID, Customer, Return Against...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF764BA2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3436)),
      ),
      body: Consumer<SalesReturnController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            // Start shimmer animation when loading
            if (!_animationController.isAnimating) {
              _animationController.repeat();
            }
            return _buildShimmerLoading();
          } else {
            // Stop shimmer animation when not loading
            if (_animationController.isAnimating) {
              _animationController.stop();
              _animationController.reset();
            }
            // Start fade-in animation for content
            _animationController.forward();
          }

          if (controller.error != null && controller.error!.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF764BA2),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Sales Returns Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull to refresh or start by creating your first return',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final salesReturns = controller.salesreturnList!.message.data ?? [];
          final filteredSalesReturns = _filterSalesReturns(salesReturns);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF764BA2),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search results info
                    if (_searchQuery.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF764BA2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF764BA2),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Found ${filteredSalesReturns.length} result${filteredSalesReturns.length != 1 ? 's' : ''} for "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF764BA2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Color(0xFF764BA2),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // List Items
                    Expanded(
                      child:
                          filteredSalesReturns.isEmpty &&
                              _searchQuery.isNotEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No results found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
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
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredSalesReturns.length,
                              itemBuilder: (context, index) {
                                final data = filteredSalesReturns[index];
                                final statusColor = _getStatusColor(
                                  data.workflowState,
                                );

                                // Calculate total quantity from items
                                double totalQty = 0;
                                if (data.items.isNotEmpty) {
                                  totalQty = data.items.fold(
                                    0,
                                    (sum, item) => sum + (item.qty.abs() ?? 0),
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: statusColor,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header Section
                                            Row(
                                              children: [
                                                Hero(
                                                  tag:
                                                      'return_${data.name}_$index',
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          statusColor,
                                                          statusColor
                                                              .withOpacity(0.7),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.assignment_return,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        data.name ?? 'Unknown',
                                                        style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                            0xFF2C3E50,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Customer: ${data.customer ?? 'Unknown'}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Status as container
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: statusColor,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    data.workflowState ??
                                                        'No Status',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 16),

                                            // Details Section
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F9FA),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  // Quantity Row
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF27AE60,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF27AE60,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Total Quantity',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              totalQty
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 12),

                                                  // Date Row
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF3498DB,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF3498DB,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Posting Date',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              data.postingDate,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 12),

                                                  // Sales Person Row
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons.person_outlined,
                                                          size: 16,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Sales Person',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              data.customSalesPerson,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  // Return Against Section (only if return_against exists)
                                                  if (data.returnAgainst !=
                                                          null &&
                                                      data
                                                          .returnAgainst!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFF9B59B6,
                                                            ).withOpacity(0.1),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.link_outlined,
                                                            size: 16,
                                                            color: Color(
                                                              0xFF9B59B6,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Return Against',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey[600],
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Text(
                                                                data.returnAgainst!,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF2C3E50,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
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
                                            if (data.returnReason != null &&
                                                data
                                                    .returnReason!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF9B59B6,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.link_outlined,
                                                      size: 16,
                                                      color: Color(0xFF9B59B6),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Return Reason',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          data.returnReason!,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF2C3E50,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            // Items Section
                                            if (data.items.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Items (${data.items.length})',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF2C3E50,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    ...data.items
                                                        .map(
                                                          (item) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    item.itemName ??
                                                                        item.itemCode ??
                                                                        'Unknown Item',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Color(
                                                                        0xFF2C3E50,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Qty: ${item.qty.abs() ?? 0}',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .grey[600],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSalesReturnPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFF764BA2),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Return',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // List Items Shimmer
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header shimmer
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: _buildShimmerContainer(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Details shimmer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Multiple shimmer rows
                            ...List.generate(
                              3,
                              (index) => Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Colors.grey[200],
                                        ),
                                        child: _buildShimmerContainer(),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 60 + index * 20.0,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color: Colors.grey[200],
                                              ),
                                              child: _buildShimmerContainer(),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              width: 100 + index * 30.0,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color: Colors.grey[200],
                                              ),
                                              child: _buildShimmerContainer(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (index < 2) const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer() {
    return Container(decoration: BoxDecoration(color: Colors.grey[300]));
  }
}
