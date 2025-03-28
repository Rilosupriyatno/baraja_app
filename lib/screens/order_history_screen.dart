import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/currency_formatter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'History Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.brown,
          tabs: const [
            Tab(text: 'Process'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Process (Ongoing orders)
          _buildOrdersList(isCompleted: false),

          // Tab 2: Done (Completed orders)
          _buildOrdersList(isCompleted: true),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required bool isCompleted}) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Filter orders based on tab
        final List<Order> orders = orderProvider.allOrders.where((order) {
          if (isCompleted) {
            return order.status == OrderStatus.completed;
          } else {
            return order.status != OrderStatus.completed &&
                order.status != OrderStatus.cancelled;
          }
        }).toList();

        // Sort by date, newest first
        orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));

        if (orders.isEmpty) {
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderItem(context, orders[index]);
          },
        );
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    // Get first item as the representative
    final firstItem = order.items.first;

    return Container(
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

                  // Item customizations
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

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(firstItem.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'x${firstItem.quantity}',
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
    );
  }

  String _buildCustomizationText(CartItem item) {
    List<String> customizations = [];

    if (item.additional != '-') {
      customizations.add(item.additional);
    }

    if (item.topping != '-') {
      customizations.add(item.topping);
    }

    return customizations.join(', ');
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
}