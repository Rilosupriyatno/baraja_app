import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'payment_row_widget.dart';

class OrderDetailWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailWidget({super.key, required this.orderData});

  // Method untuk mendapatkan status pembayaran
  Map<String, dynamic> _getPaymentStatus(String status) {
    switch (status) {
      case 'settlement':
      case 'capture':
        return {
          'label': 'Lunas',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case 'pending':
        return {
          'label': 'Menunggu Pembayaran',
          'icon': Icons.access_time,
          'color': Colors.orange,
        };
      case 'expire':
        return {
          'label': 'Kadaluarsa',
          'icon': Icons.timer_off,
          'color': Colors.red,
        };
      case 'cancel':
        return {
          'label': 'Dibatalkan',
          'icon': Icons.cancel,
          'color': Colors.red,
        };
      case 'deny':
        return {
          'label': 'Ditolak',
          'icon': Icons.block,
          'color': Colors.red,
        };
      case 'failure':
        return {
          'label': 'Gagal',
          'icon': Icons.error,
          'color': Colors.red,
        };
      default:
        return {
          'label': 'Status Tidak Diketahui',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List? ?? [];
    final paymentStatus = _getPaymentStatus(orderData['paymentStatus']);
    print(orderData['paymentStatus']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderData['orderNumber'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.barajaPrimary.primaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        orderData['orderDate'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.barajaPrimary.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Detail Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: AppTheme.barajaPrimary.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Detail Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Loop through all items
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Container(
                    margin: EdgeInsets.only(bottom: index < items.length - 1 ? 16 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: (item['imageUrl'] != null &&
                                  item['imageUrl'].toString().isNotEmpty &&
                                  item['imageUrl'] != 'https://placehold.co/1920x1080/png')
                                  ? Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/product_default_image.jpeg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                },
                              )
                                  : Image.asset(
                                'assets/images/product_default_image.jpeg',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'x${item['quantity'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(item['price'] ?? 0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Addons Section
                        if (item['addons'] != null &&
                            item['addons'] is List &&
                            (item['addons'] as List).isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Tambahan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (item['addons'] as List).map((addon) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.circle, size: 6, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${addon["name"] ?? ""}: ${addon["label"] ?? ""}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(addon["price"] ?? 0),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              )).cast<Widget>().toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Topping Section
                        if (item['toppings'] != null &&
                            ((item['toppings'] is String && (item['toppings'] as String).isNotEmpty) ||
                                (item['toppings'] is List && (item['toppings'] as List).isNotEmpty))) ...[
                          const Row(
                            children: [
                              Icon(Icons.cake, size: 16, color: Colors.deepOrange),
                              SizedBox(width: 4),
                              Text(
                                'Topping:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                            ),
                            child: _buildToppingsWidget(item['toppings']),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Notes Section
                        if (item['notes'] != null &&
                            item['notes'].toString().isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.note_outlined, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Catatan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.format_quote, size: 14, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['notes'].toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Elegant Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Payment Detail Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Rincian Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                PaymentRowWidget(
                  label: 'Total',
                  value: formatCurrency(orderData['total'] ?? 0),
                  icon: Icons.receipt,
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                PaymentRowWidget(
                  label: 'Metode Pembayaran',
                  value: orderData['paymentMethod'] ?? '',
                  icon: Icons.credit_card,
                  isTotal: false,
                ),
                const SizedBox(height: 12),
                // Custom Payment Status Widget
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: paymentStatus['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: paymentStatus['color'].withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        paymentStatus['icon'],
                        size: 20,
                        color: paymentStatus['color'],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: paymentStatus['color'],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          paymentStatus['label'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build toppings widget based on type
  Widget _buildToppingsWidget(dynamic toppings) {
    if (toppings is List && toppings.isNotEmpty && toppings.first is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: toppings.map<Widget>((topping) {
          if (topping is Map) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${topping["name"] ?? ""}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (topping.containsKey("price") && topping["price"] != null)
                    Text(
                      formatCurrency(topping["price"] as num),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepOrange,
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }).toList(),
      );
    } else {
      return Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              toppings is String
                  ? toppings
                  : toppings is List
                  ? toppings.join(', ')
                  : '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }
  }
}