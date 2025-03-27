import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../utils/order_tracking_helper.dart';

class OrderStatusCard extends StatelessWidget {
  final Order order;

  const OrderStatusCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = OrderTrackingHelper.getStatusColor(order.status);
    final IconData statusIcon = OrderTrackingHelper.getStatusIcon(order.status);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    OrderTrackingHelper.getStatusDescription(order.status, order.orderType),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}