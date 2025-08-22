import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'payment_row_widget.dart';

class OrderDetailWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailWidget({super.key, required this.orderData});

  // Method untuk mendapatkan status pembayaran
  Map<String, dynamic> _getPaymentStatus(String? status) {
    // ✅ PERBAIKAN: Handle null status
    if (status == null) {
      return {
        'label': 'Status Tidak Diketahui',
        'icon': Icons.help_outline,
        'color': Colors.grey,
      };
    }

    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
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

    // ✅ PERBAIKAN: Safe access untuk paymentStatus
    final paymentStatusValue = orderData['paymentStatus']?.toString();
    final paymentStatus = _getPaymentStatus(paymentStatusValue);

    print('Payment Status Value: $paymentStatusValue');

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
                          orderData['orderNumber']?.toString() ?? 'No Order Number',
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
                        orderData['orderDate']?.toString() ?? 'No Date',
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
                              child: _buildItemImage(item),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name']?.toString() ?? 'Unknown Item',
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
                                'x${item['quantity']?.toString() ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(_getNumericValue(item['price'])),
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
                        ..._buildAddonsSection(item),

                        // Topping Section
                        ..._buildToppingsSection(item),

                        // Notes Section
                        ..._buildNotesSection(item),
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
                  value: formatCurrency(_getNumericValue(orderData['total'])),
                  icon: Icons.receipt,
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                PaymentRowWidget(
                  label: 'Metode Pembayaran',
                  value: orderData['paymentMethod']?.toString() ?? 'Not specified',
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

  // ✅ HELPER METHODS untuk null safety

  Widget _buildItemImage(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl']?.toString();

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        imageUrl != 'https://placehold.co/1920x1080/png') {
      return Image.network(
        imageUrl,
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
      );
    } else {
      return Image.asset(
        'assets/images/product_default_image.jpeg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  List<Widget> _buildAddonsSection(Map<String, dynamic> item) {
    final addons = item['addons'];

    if (addons == null ||
        (addons is List && addons.isEmpty) ||
        (addons is String && addons.isEmpty)) {
      return [];
    }

    return [
      const Row(
        children: [
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
        child: _buildAddonsContent(addons),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildAddonsContent(dynamic addons) {
    if (addons is List && addons.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: addons.map<Widget>((addon) {
          if (addon is Map) {
            return Padding(
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
                            '${addon["name"]?.toString() ?? ""}: ${addon["label"]?.toString() ?? ""}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatCurrency(_getNumericValue(addon["price"])),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      );
    }

    return Text(
      addons?.toString() ?? '',
      style: const TextStyle(fontSize: 14),
    );
  }

  List<Widget> _buildToppingsSection(Map<String, dynamic> item) {
    final toppings = item['toppings'];

    if (toppings == null ||
        (toppings is String && toppings.isEmpty) ||
        (toppings is List && toppings.isEmpty)) {
      return [];
    }

    return [
      const Row(
        children: [
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
        child: _buildToppingsWidget(toppings),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildNotesSection(Map<String, dynamic> item) {
    final notes = item['notes']?.toString();

    if (notes == null || notes.isEmpty) {
      return [];
    }

    return [
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
                notes,
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
    ];
  }

  // Helper method to safely get numeric values
  num _getNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
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
                            topping["name"]?.toString() ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (topping.containsKey("price") && topping["price"] != null)
                    Text(
                      formatCurrency(_getNumericValue(topping["price"])),
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
                  : toppings?.toString() ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }
  }
}