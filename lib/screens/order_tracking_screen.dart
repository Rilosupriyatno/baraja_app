import 'dart:async';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/order_tracking_helper.dart';
import '../widgets/order/order_details_card.dart';
import '../widgets/order/order_status_card.dart';
import '../widgets/order/order_summary_card.dart';
import '../widgets/order/order_timeline.dart';
import '../widgets/utils/classic_app_bar.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Simulasi perubahan status pesanan setiap 15 detik
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _simulateStatusUpdate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Simulasi perubahan status pesanan
  void _simulateStatusUpdate() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.getOrderById(widget.orderId);

    if (order != null) {
      // Gunakan helper untuk menentukan status berikutnya
      final newStatus = OrderTrackingHelper.getNextStatus(order.status, order.orderType);

      // Jika ada perubahan status, update
      if (newStatus != order.status) {
        orderProvider.updateOrderStatus(widget.orderId, newStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final order = orderProvider.getOrderById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: const ClassicAppBar(title: 'Lacak Pesanan'),
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
      appBar: const ClassicAppBar(title: 'Lacak Pesanan'),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh untuk keperluan demo
          setState(() {});
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID dan waktu pemesanan
              Text(
                'ID Pesanan: ${order.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),

              Text(
                'Waktu Pesan: ${OrderTrackingHelper.formatDateTime(order.orderTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              // Widget-widget yang sudah direfaktor
              OrderStatusCard(order: order),
              const SizedBox(height: 24),

              OrderTimeline(order: order),
              const SizedBox(height: 24),

              OrderSummaryCard(order: order),
              const SizedBox(height: 24),

              OrderDetailsCard(order: order),
              const SizedBox(height: 24),

              // Contact support section
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur hubungi customer service belum tersedia'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Hubungi Customer Service'),
                ),
              ),
            ],
          ),
        ),
      ),

      // Button untuk demo update status
      bottomNavigationBar: order.status != OrderStatus.completed && order.status != OrderStatus.cancelled ?
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Manual update untuk keperluan demo
            _simulateStatusUpdate();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status pesanan telah diperbarui'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Perbarui Status (Demo)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ) : null,
    );
  }
}