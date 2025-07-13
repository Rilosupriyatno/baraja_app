import 'package:flutter/material.dart';

class StatusSectionWidget extends StatelessWidget {
  final String orderStatus;
  final Color statusColor;
  final IconData statusIcon;
  final Animation<double> pulseAnimation;
  final Map<String, dynamic>? orderData;

  const StatusSectionWidget({
    super.key,
    required this.orderStatus,
    required this.statusColor,
    required this.statusIcon,
    required this.pulseAnimation,
    this.orderData,
  });

  // Helper method to get comprehensive status info
  Map<String, dynamic> _getStatusInfo() {
    if (orderData == null) return {};

    final paymentStatus = orderData!['paymentStatus'] ?? '';
    final orderStatusValue = orderData!['orderStatus'] ?? '';

    // Prioritize order status if payment is successful
    if (paymentStatus == 'settlement' || paymentStatus == 'capture') {
      return _getOrderStatusInfo(orderStatusValue);
    } else {
      return _getPaymentStatusInfo(paymentStatus);
    }
  }

  // Get order status information when payment is successful
  Map<String, dynamic> _getOrderStatusInfo(String orderStatusValue) {
    switch (orderStatusValue) {
      case 'Pending':
        return {
          'subtitle': 'Menunggu konfirmasi dari kasir',
          'description': 'Pesanan Anda akan segera diproses',
          'showPulse': true,
        };
      case 'Waiting':
        return {
          'subtitle': 'Menunggu konfirmasi dari dapur',
          'description': 'Pesanan Anda akan segera diproses oleh chef',
          'showPulse': true,
        };
      case 'OnProcess':
        return {
          'subtitle': 'Sedang diproses oleh dapur',
          'description': 'Chef sedang menyiapkan pesanan Anda',
          'showPulse': true,
        };
      case 'Ready':
        return {
          'subtitle': 'Pesanan siap!',
          'description': 'Silakan ambil pesanan Anda',
          'showPulse': true,
        };
      case 'OnTheWay':
        return {
          'subtitle': 'Dalam perjalanan',
          'description': 'Pesanan Anda sedang diantar ke alamat tujuan',
          'showPulse': true,
        };
      case 'Completed':
        return {
          'subtitle': 'Pesanan selesai',
          'description': 'Terima kasih telah memesan di Baraja Coffee',
          'showPulse': false,
        };
      case 'Canceled':
      case 'Cancelled':
        return {
          'subtitle': 'Pesanan dibatalkan',
          'description': 'Pesanan telah dibatalkan',
          'showPulse': false,
        };
      default:
        return {
          'subtitle': 'Status pesanan',
          'description': 'Pesanan Anda sedang diproses',
          'showPulse': true,
        };
    }
  }

  // Get payment status information when payment is not successful
  Map<String, dynamic> _getPaymentStatusInfo(String paymentStatus) {
    switch (paymentStatus) {
      case 'expire':
        return {
          'subtitle': 'Pembayaran telah kadaluarsa',
          'description': 'Silakan buat pesanan baru untuk melanjutkan',
          'showPulse': false,
        };
      case 'pending':
        return {
          'subtitle': 'Menunggu pembayaran Anda',
          'description': 'Selesaikan pembayaran sebelum waktu habis',
          'showPulse': true,
        };
      case 'cancel':
        return {
          'subtitle': 'Pembayaran dibatalkan',
          'description': 'Pesanan telah dibatalkan',
          'showPulse': false,
        };
      default:
        return {
          'subtitle': 'Status pembayaran',
          'description': 'Menunggu konfirmasi pembayaran',
          'showPulse': true,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    final shouldPulse = statusInfo['showPulse'] ?? true;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      if (statusInfo['subtitle'] != null && statusInfo['subtitle'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusInfo['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: statusColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (statusInfo['description'] != null && statusInfo['description'].isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          statusInfo['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: shouldPulse ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ] : [],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}