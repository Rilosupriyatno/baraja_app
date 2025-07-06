import 'package:flutter/material.dart';

class StatusSectionWidget extends StatelessWidget {
  final String orderStatus;
  final Color statusColor;
  final IconData statusIcon;
  final Animation<double> pulseAnimation;
  final Map<String, dynamic>? orderData; // Add orderData parameter

  const StatusSectionWidget({
    super.key,
    required this.orderStatus,
    required this.statusColor,
    required this.statusIcon,
    required this.pulseAnimation,
    this.orderData, // Optional parameter
  });

  // Helper method to get payment status info
  Map<String, dynamic> _getPaymentStatusInfo() {
    if (orderData == null) return {};

    final paymentStatus = orderData!['paymentStatus'] ?? '';

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
      case 'settlement':
      case 'capture':
        return {
          'subtitle': 'Pembayaran berhasil',
          'description': 'Pesanan Anda sedang diproses',
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
          'subtitle': '',
          'description': '',
          'showPulse': true,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentInfo = _getPaymentStatusInfo();
    final shouldPulse = paymentInfo['showPulse'] ?? true;

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
                      if (paymentInfo['subtitle'] != null && paymentInfo['subtitle'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          paymentInfo['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: statusColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (paymentInfo['description'] != null && paymentInfo['description'].isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          paymentInfo['description'],
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