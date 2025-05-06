import 'package:flutter/material.dart';

class PaymentStatusCard extends StatelessWidget {
  final Map<String, dynamic>? paymentResponse;
  final String orderId;

  const PaymentStatusCard({
    super.key,
    required this.paymentResponse,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final status = paymentResponse?['transaction_status'] ?? 'unknown';
    final isSuccess = status == 'settlement';
    final isPending = status == 'pending';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;
    String statusText = 'Unknown Status';

    if (isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Pembayaran Berhasil';
    } else if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_outlined;
      statusText = 'Menunggu Pembayaran';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Pembayaran Gagal';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (paymentResponse != null) ...[
            const SizedBox(height: 8),
            Text(
              'Order ID: ${paymentResponse!['order_id'] ?? orderId}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (paymentResponse!['transaction_time'] != null)
              Text(
                'Waktu: ${paymentResponse!['transaction_time']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ],
      ),
    );
  }
}