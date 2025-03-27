import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/order_type.dart';
import '../../utils/order_tracking_helper.dart';

class OrderDetailsCard extends StatelessWidget {
  final Order order;

  const OrderDetailsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Order type
            _buildDetailItem('Tipe Pesanan', OrderTrackingHelper.getOrderTypeText(order.orderType)),

            // Order type specific details
            if (order.orderType == OrderType.dineIn && order.tableNumber.isNotEmpty)
              _buildDetailItem('Nomor Meja', order.tableNumber),

            if (order.orderType == OrderType.delivery && order.deliveryAddress.isNotEmpty)
              _buildDetailItem('Alamat Pengantaran', order.deliveryAddress),

            if (order.orderType == OrderType.pickup && order.pickupTime != null)
              _buildDetailItem('Waktu Pengambilan',
                  '${order.pickupTime!.hour}:${order.pickupTime!.minute.toString().padLeft(2, '0')}'),

            // Payment method
            _buildDetailItem('Metode Pembayaran', order.paymentMethod),

            // Voucher if used
            if (order.voucherCode != null && order.voucherCode!.isNotEmpty)
              _buildDetailItem('Voucher', order.voucherCode!),
          ],
        ),
      ),
    );
  }

  // Helper untuk detail item
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}