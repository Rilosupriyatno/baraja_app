import 'package:baraja_app/theme/app_theme.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
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
      // ✅ Tampilkan order di terminal
      for (var order in orders) {
        print('Order ID: ${order.id}');
        print('Status: ${order.status}');
        print('Total: ${order.total}');
        print('Order Time: ${order.orderTime}');
        print('Items:');
        for (var item in order.items) {
          print(' - ${item.name}');
        }
        print('----------------------');
      }
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
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
            const ClassicAppBar(title: 'History'),
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
          ? Center(child: Text(_errorMessage))
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
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
                  image: DecorationImage(
                    image: NetworkImage(firstItem.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback jika gambar gagal dimuat
                    },
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
                    ),
                    const SizedBox(height: 4),

                    // Order time and order ID
                    Text(
                      '${_formatDate(order.orderTime)} • ID: ${order.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status pesanan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Item customizations
                    if (firstItem.addons != '-' || firstItem.toppings != '-')
                      Text(
                        _buildCustomizationText(firstItem),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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

                    const SizedBox(height: 8),

                    // Action button
                    order.status == OrderStatus.completed
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // Implement reorder functionality
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.brown,
                            side: const BorderSide(color: Colors.brown),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Order Again',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        buildRatingWidget(),
                      ],
                    )
                        : OutlinedButton(
                      onPressed: () {
                        // Navigate to tracking using GoRouter
                        context.go('/tracking', extra: order.id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.brown,
                        side: const BorderSide(color: Colors.brown),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Tracking Order',
                        style: TextStyle(fontSize: 12),
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

  Widget buildRatingWidget() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          '5',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Review',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.onTheWay:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green.shade800;
      case OrderStatus.cancelled:
        return Colors.red;
      }
  }
}