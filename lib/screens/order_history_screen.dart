import 'package:baraja_amphitheater_app/theme/app_theme.dart';
import 'package:baraja_amphitheater_app/utils/base_screen_wrapper.dart';
import 'package:baraja_amphitheater_app/widgets/utils/title_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../services/order_service.dart';
import '../utils/currency_formatter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final GlobalKey<RefreshIndicatorState> _processRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _doneRefreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orders = await _orderService.getUserOrderHistory();

      print('📦 Total orders loaded: ${orders.length}');
      for (var order in orders) {
        print('Order ID: ${order.id}');
        print('Status: ${order.status}');
        print('Payment Status: ${order.paymentDetails['status']}');
        print('Total: ${order.total}');
        print('Items count: ${order.items.length}');
        print('----------------------');
      }

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading order history: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat riwayat pesanan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshData() async {
    await _fetchOrderHistory();
  }

  // Dummy orders untuk skeleton
  List<Order> _getDummyOrders() {
    return List.generate(
      3,
          (index) => Order(
        id: 'dummy_order_$index',
        orderId: 'ORD${index}12345678',
        items: [
          CartItem(
            id: 'dummy_item_$index',
            name: 'Loading Product Name Loading',
            imageUrl: '',
            price: 50000,
            quantity: 1,
            addons: [],
            toppings: [],
            notes: 'Loading notes',
            totalprice: 50000,
            outletId: 'dummy_outlet',
            outletName: 'Loading Outlet',
          ),
          CartItem(
            id: 'dummy_item_${index}_2',
            name: 'Loading Product Name 2',
            imageUrl: '',
            price: 35000,
            quantity: 1,
            addons: [],
            toppings: [],
            notes: '',
            totalprice: 35000,
            outletId: 'dummy_outlet',
            outletName: 'Loading Outlet',
          ),
        ],
        orderType: OrderType.dineIn,
        tableNumber: 'A${index + 1}',
        deliveryAddress: '',
        pickupTime: null,
        subtotal: 85000,
        discount: 0,
        total: 93500,
        voucherCode: null,
        orderTime: DateTime.now(),
        status: OrderStatus.pending,
        paymentDetails: {
          'status': 'pending',
          'method': 'Loading',
        },
        taxAmount: 8500,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: '/main',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const TitleAppBar(title: 'History'),
              Material(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(text: 'Berlangsung'),
                    Tab(text: 'Selesai'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrderHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Process (Ongoing orders)
            RefreshIndicator(
              key: _processRefreshKey,
              onRefresh: _fetchOrderHistory,
              child: _buildOrdersList(isCompleted: false),
            ),

            // Tab 2: Done (Completed orders)
            RefreshIndicator(
              key: _doneRefreshKey,
              onRefresh: _fetchOrderHistory,
              child: _buildOrdersList(isCompleted: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList({required bool isCompleted}) {
    // Get display orders (dummy when loading, real when loaded)
    List<Order> displayOrders;

    if (_isLoading) {
      displayOrders = _getDummyOrders();
    } else {
      // Filter orders based on tab
      displayOrders = _orders.where((order) {
        if (isCompleted) {
          return order.status == OrderStatus.completed;
        } else {
          return order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled;
        }
      }).toList();

      // Sort by date, newest first
      displayOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
    }

    if (displayOrders.isEmpty && !_isLoading) {
      // Empty state
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCompleted
                        ? 'Belum ada pesanan selesai'
                        : 'Belum ada pesanan dalam proses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tarik ke bawah untuk memperbarui',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Skeletonizer(
      enabled: _isLoading,
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        itemCount: displayOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderItem(context, displayOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    // Pastikan ada item sebelum mengakses first
    if (order.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get first item as the representative
    final firstItem = order.items.first;

    return InkWell(
      onTap: _isLoading
          ? null // Disable tap when loading
          : () {
        context.go('/orderDetail', extra: order.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: firstItem.imageUrl.isNotEmpty &&
                      firstItem.imageUrl != 'https://placehold.co/1920x1080/png'
                      ? Image.network(
                    firstItem.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/product_default_image.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    },
                  )
                      : Image.asset(
                    'assets/images/product_default_image.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstItem.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Order time and order ID
                    Text(
                      '${_formatDate(order.orderTime)} • ID: ${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status pesanan
                    Row(
                      children: [
                        const SizedBox(width: 8),

                        // Payment status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(order.paymentDetails['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPaymentStatusText(order.paymentDetails['status']),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPaymentStatusColor(order.paymentDetails['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // If there are more items, show count
                    if (order.items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${order.items.length - 1} more items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Price and total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} items',
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentStatusText(String? paymentStatus) {
    switch (paymentStatus?.toLowerCase()) {
      case 'settlement':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'partial':
        return 'Menunggu Pelunasan';
      case 'capture':
        return 'Lunas';
      case 'deny':
        return 'Ditolak';
      case 'cancel':
        return 'Dibatalkan';
      case 'expire':
      case 'Unpaid':
        return 'Kadaluarsa';
      case 'failure':
        return 'Gagal';
      default:
        return paymentStatus ?? 'Unknown';
    }
  }

  Color _getPaymentStatusColor(String? paymentStatus) {
    switch (paymentStatus?.toLowerCase()) {
      case 'settlement':
      case 'capture':
        return Colors.green;
      case 'partial':
        return Colors.deepOrange;
      case 'pending':
        return Colors.orange;
      case 'deny':
      case 'cancel':
      case 'failure':
        return Colors.red;
      case 'expire':
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}