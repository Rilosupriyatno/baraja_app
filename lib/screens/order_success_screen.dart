import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final order = orderProvider.getOrderById(orderId);

    if (order == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Order tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/main'),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 96,
              ),
              const SizedBox(height: 24),

              // Success Message
              const Text(
                'Pesanan Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Order ID
              Text(
                'ID Pesanan: ${order.id}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Order Status
              Text(
                'Status: ${order.statusText}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Order Type Info
              _buildOrderTypeInfo(order),
              const SizedBox(height: 24),

              // Thank You Message
              Text(
                'Terima kasih atas pesanan Anda!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Track Order Button
              ElevatedButton(
                onPressed: () => context.go('/tracking', extra: orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lacak Pesanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Home Button
              TextButton(
                onPressed: () => context.go('/main'),
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to display order type specific information
  Widget _buildOrderTypeInfo(Order order) {
    String message = '';

    switch (order.orderType) {
      case OrderType.dineIn:
        message = 'Silakan duduk di meja ${order.tableNumber}.\nPesanan Anda akan segera disiapkan.';
        break;
      case OrderType.delivery:
        message = 'Pesanan Anda akan dikirim ke:\n${order.deliveryAddress}';
        break;
      case OrderType.pickup:
        final timeText = order.pickupTime != null
            ? '${order.pickupTime!.hour}:${order.pickupTime!.minute.toString().padLeft(2, '0')}'
            : 'waktu yang ditentukan';
        message = 'Pesanan Anda akan siap untuk diambil pada $timeText';
        break;
    }

    return Text(
      message,
      style: const TextStyle(fontSize: 16),
      textAlign: TextAlign.center,
    );
  }
}