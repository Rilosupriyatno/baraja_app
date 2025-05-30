import 'package:baraja_app/theme/app_theme.dart';
import 'package:baraja_app/widgets/utils/title_app_bar.dart';
// import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/order.dart';
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

      // // Debug: Print orders untuk memastikan data tersambung dengan benar
      print('📦 Total orders loaded: ${orders.length}');
      for (var order in orders) {
        print('Order ID: ${order.id}');
        print('Status: ${order.status}');
        print('Payment Status: ${order.paymentDetails['status']}');
        print('Total: ${order.total}');
        print('Items count: ${order.items.length}');
        print('----------------------');
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading order history: $e');
      setState(() {
        _errorMessage = 'Gagal memuat riwayat pesanan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(104), // tinggi AppBar + TabBar
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
                  Tab(text: 'Process'),
                  Tab(text: 'Done'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
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
          : RefreshIndicator(
        onRefresh: _fetchOrderHistory,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Process (Ongoing orders)
            _buildOrdersList(isCompleted: false),

            // Tab 2: Done (Completed orders)
            _buildOrdersList(isCompleted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList({required bool isCompleted}) {
    // Filter orders based on tab
    final List<Order> filteredOrders = _orders.where((order) {
      if (isCompleted) {
        return order.status == OrderStatus.completed;
      } else {
        return order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled;
      }
    }).toList();

    // Sort by date, newest first
    filteredOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));

    if (filteredOrders.isEmpty) {
      return ListView(
        // Tambahkan padding bottom agar tidak tertutup bottom navigation
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80, // 80 adalah tinggi bottom navigation bar
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
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      // Tambahkan padding agar list tidak tertutup bottom navigation
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 6, // 80 adalah tinggi bottom navigation bar
      ),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderItem(context, filteredOrders[index]);
      },
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
      onTap: () {
        // Navigate to OrderDetailScreen
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
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
                        'assets/images/product_default_image.jpeg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    },
                  )
                      : Image.asset(
                    'assets/images/product_default_image.jpeg',
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
                        // Status utama pesanan
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //   decoration: BoxDecoration(
                        //     color: _getOrderStatusColor(order.status).withOpacity(0.1),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Text(
                        //     _getOrderStatusText(order.status),
                        //     style: TextStyle(
                        //       fontSize: 11,
                        //       color: _getOrderStatusColor(order.status),
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),

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

                    // Item customizations
                    if (_hasCustomizations(firstItem))
                      Text(
                        _buildCustomizationText(firstItem),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

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

  bool _hasCustomizations(dynamic item) {
    return (item.addons != null && item.addons.isNotEmpty) ||
        (item.toppings != null && item.toppings.isNotEmpty);
  }

  String _buildCustomizationText(dynamic item) {
    List<String> customizations = [];

    if (item.addons != null && item.addons.isNotEmpty) {
      List<String> addonNames = [];
      for (var addon in item.addons) {
        if (addon['name'] != null && addon['name'].isNotEmpty) {
          addonNames.add(addon['name']);
        }
      }
      if (addonNames.isNotEmpty) {
        customizations.add(addonNames.join(', '));
      }
    }

    if (item.toppings != null && item.toppings.isNotEmpty) {
      List<String> toppingNames = [];
      for (var topping in item.toppings) {
        if (topping['name'] != null && topping['name'].isNotEmpty) {
          toppingNames.add(topping['name']);
        }
      }
      if (toppingNames.isNotEmpty) {
        customizations.add(toppingNames.join(', '));
      }
    }

    return customizations.isEmpty ? '-' : customizations.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  // String _getOrderStatusText(OrderStatus status) {
  //   switch (status) {
  //     case OrderStatus.pending:
  //       return 'Menunggu Konfirmasi';
  //     // case OrderStatus.confirmed:
  //     //   return 'Dikonfirmasi';
  //     // case OrderStatus.preparing:
  //     //   return 'Sedang Disiapkan';
  //     // case OrderStatus.readyForPickup:
  //     //   return 'Siap Diambil';
  //     case OrderStatus.completed:
  //       return 'Selesai';
  //     case OrderStatus.cancelled:
  //       return 'Dibatalkan';
  //     default:
  //       return 'Unknown';
  //   }
  // }
  //
  // Color _getOrderStatusColor(OrderStatus status) {
  //   switch (status) {
  //     case OrderStatus.pending:
  //       return Colors.orange;
  //     // case OrderStatus.confirmed:
  //     //   return Colors.blue;
  //     // case OrderStatus.preparing:
  //     //   return Colors.purple;
  //     // case OrderStatus.readyForPickup:
  //     //   return Colors.green;
  //     case OrderStatus.completed:
  //       return Colors.green.shade700;
  //     case OrderStatus.cancelled:
  //       return Colors.red;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  String _getPaymentStatusText(String? paymentStatus) {
    switch (paymentStatus?.toLowerCase()) {
      case 'settlement':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'capture':
        return 'Lunas';
      case 'deny':
        return 'Ditolak';
      case 'cancel':
        return 'Dibatalkan';
      case 'expire':
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
      case 'pending':
        return Colors.orange;
      case 'deny':
      case 'cancel':
      case 'failure':
        return Colors.red;
      case 'expire':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}