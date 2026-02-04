import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/sales_order_controller.dart';
import 'package:location_tracker_app/modal/sales_order_modal.dart' as modal;
import 'package:location_tracker_app/view/mainscreen/sales_order/create_sales_order/create_sales_order.dart';
import 'package:location_tracker_app/view/mainscreen/sales_order/create_sales_order/stock.dart';
import 'package:location_tracker_app/view/mainscreen/sales_order/sales_return.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SalesOrdersListPage extends StatefulWidget {
  const SalesOrdersListPage({super.key});

  @override
  _SalesOrdersListPageState createState() => _SalesOrdersListPageState();
}

class _SalesOrdersListPageState extends State<SalesOrdersListPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  final String _selectedFilter = 'All';
  final bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalesOrders();
    });
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Method to load sales orders
  Future<void> _loadSalesOrders() async {
    await Provider.of<SalesOrderController>(
      context,
      listen: false,
    ).fetchsalesorder();
  }

  // Refresh method for pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadSalesOrders();
    // Optional: Show a success message
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SalesOrderController>(
        builder: (context, controller, child) {
          final filteredOrders =
              controller.salesorder?.message.salesOrders ?? [];

          return Container(
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
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      backgroundColor: Colors.white,
                      color: Color(0xFF764BA2),
                      strokeWidth: 3,
                      displacement: 40,
                      child: _buildOrdersList(
                        salesOrders: filteredOrders,
                        controller: controller,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0), // 👈 move up by 20px
        child: _buildUniqueFloatingButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
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
            child: Icon(Icons.receipt_long, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Orders',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),

          // Manual refresh button
          PopupMenuButton<String>(
            key: const Key('filterPopupMenu'),
            icon: const Icon(Icons.filter_list, color: Color(0xFF2D3436)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'salesReturn',
                  child: Text('Sales Returns'),
                ),
                PopupMenuItem(value: 'stocks', child: Text('Stocks')),
              ];
            },
            onSelected: (value) {
              if (value == 'salesReturn') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesReturnListPage(),
                  ),
                );
              } else if (value == 'stocks') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StockAvailable()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList({
    required List<modal.SalesOrder> salesOrders,
    required SalesOrderController controller,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: controller.isLoading
          ? _buildShimmerOrdersListEnhanced()
          : salesOrders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              // Add physics to ensure pull-to-refresh works even with few items
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: salesOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(salesOrders[index], index);
              },
            ),
    );
  }

  Widget _buildShimmerOrdersListEnhanced() {
    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(), // Enable scrolling for refresh
      itemCount: 6,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          margin: EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                                width: double.infinity * 0.7,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: double.infinity * 0.5,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(height: 4),
                                Container(
                                  width: 60,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: 40,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Color(0xFFE5E5E5),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(height: 4),
                                Container(
                                  width: 20,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: 30,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Color(0xFFE5E5E5),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(height: 4),
                                Container(
                                  width: 60,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: 70,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      // Make empty state scrollable for pull-to-refresh
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF764BA2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Color(0xFF764BA2).withOpacity(0.5),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No Orders Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your first sales order to get started',
                style: TextStyle(fontSize: 16, color: Color(0xFF636E72)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              // Refresh button in empty state
              ElevatedButton.icon(
                onPressed: _onRefresh,
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF764BA2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(modal.SalesOrder order, int index) {
    double roundedTotal = order.grandTotal.roundToDouble();
    bool hasRounding = roundedTotal != order.grandTotal;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF764BA2).withOpacity(0.1),
                            Color(0xFF667EEA).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Color(0xFF764BA2),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            order.customer,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF636E72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAmountDetail(
                          order.grandTotal,
                          roundedTotal,
                          hasRounding,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Color(0xFFE5E5E5)),
                      Expanded(
                        child: _buildOrderDetail(
                          'Items',
                          '${order.items.length}',
                        ),
                      ),
                      Container(width: 1, height: 40, color: Color(0xFFE5E5E5)),
                      Expanded(
                        child: _buildOrderDetail(
                          'Delivery Date',
                          DateFormat('yMMMd').format(order.deliveryDate),
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
    );
  }

  Widget _buildAmountDetail(
    double grandTotal,
    double roundedTotal,
    bool hasRounding,
  ) {
    return Column(
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF636E72),
          ),
        ),
        SizedBox(height: 4),
        if (hasRounding) ...[
          // Show exact amount with strikethrough
          Text(
            '₹${grandTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF636E72),
              decoration: TextDecoration.lineThrough,
              decorationColor: Color(0xFF636E72),
            ),
          ),
          SizedBox(height: 2),
          // Show rounded amount prominently
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹${roundedTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3436),
                ),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF764BA2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Rounded',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ] else
          Text(
            '₹${grandTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Column(
      children: [
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3436),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF636E72))),
      ],
    );
  }

  Widget _buildUniqueFloatingButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: 50, right: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow effect
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF764BA2).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Animated pulse rings (moved behind main button)
                ...List.generate(2, (index) {
                  return AnimatedBuilder(
                    animation: _fabAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            1 +
                            (_fabAnimationController.value * 0.3 * (index + 1)),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                0.3 *
                                    (1 - _fabAnimationController.value) *
                                    (2 - index),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Main button (moved to top for proper touch handling)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSalesOrder(),
                      ),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF764BA2).withOpacity(0.4),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetails(modal.SalesOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order summary card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 8),
                                Text(
                                  'Order ${order.name}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                            SizedBox(height: 16),

                            _buildInfoRow(
                              Icons.person_outline,
                              'Customer',
                              order.customer,
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Order Date',
                              order.deliveryDate.toString().substring(0, 10),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Items section
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Order Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Spacer(),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Items list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: order.items.length ?? 0,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemCode,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Qty: ${item.qty} ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
