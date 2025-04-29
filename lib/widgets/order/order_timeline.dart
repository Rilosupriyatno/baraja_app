import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/order_type.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;

  const OrderTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Pesanan Dibuat',
        'description': 'Pesanan Anda telah dibuat',
        'icons': Icons.receipt_long,
        'time': order.orderTime,
        'isCompleted': true,
      },
      {
        'title': 'Pembayaran',
        'description': 'Pembayaran berhasil',
        'icons': Icons.payment,
        'time': order.orderTime.add(const Duration(minutes: 1)),
        'isCompleted': true,
      },
      {
        'title': 'Pesanan Diproses',
        'description': 'Pesanan Anda sedang diproses',
        'icons': Icons.restaurant,
        'time': order.status == OrderStatus.pending
            ? null
            : order.orderTime.add(const Duration(minutes: 5)),
        'isCompleted': order.status != OrderStatus.pending,
      },
      {
        'title': order.orderType == OrderType.delivery ? 'Pesanan Diantar' : 'Pesanan Siap',
        'description': order.orderType == OrderType.delivery
            ? 'Pesanan dalam perjalanan'
            : 'Pesanan siap diambil',
        'icons': order.orderType == OrderType.delivery ? Icons.delivery_dining : Icons.check_circle,
        'time': (order.status == OrderStatus.onTheWay ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.completed)
            ? order.orderTime.add(const Duration(minutes: 15))
            : null,
        'isCompleted': order.status == OrderStatus.onTheWay ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.completed,
      },
      {
        'title': 'Pesanan Selesai',
        'description': 'Pesanan telah selesai',
        'icons': Icons.done_all,
        'time': order.status == OrderStatus.completed
            ? order.orderTime.add(const Duration(minutes: 30))
            : null,
        'isCompleted': order.status == OrderStatus.completed,
      },
    ];

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
              'Riwayat Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Timeline steps
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> step = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: step['isCompleted'] ? Colors.green : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step['icons'],
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        if (index < steps.length - 1)
                          Container(
                            width: 2,
                            height: 30,
                            color: step['isCompleted'] ? Colors.green : Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Step details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: step['isCompleted'] ? Colors.black : Colors.grey,
                                ),
                              ),
                              if (step['time'] != null)
                                Text(
                                  '${step['time'].hour}:${step['time'].minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}