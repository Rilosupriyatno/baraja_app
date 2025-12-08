import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../tracking_detail/payment_row_widget.dart';

class GroOrderDetailWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool showAddOrderButton;
  final VoidCallback? onAddOrder;

  const GroOrderDetailWidget({
    super.key,
    required this.orderData,
    this.showAddOrderButton = false,
    this.onAddOrder,
  });

  // ✅ Method untuk menghitung total price item (konsisten dengan cart_item_card & cart_item_widget)
  num _calculateItemTotalPrice(Map<String, dynamic> item) {
    num totalPrice = _getNumericValue(item['price']);

    // Add toppings price
    final toppings = item['toppings'];
    if (toppings != null && toppings is List) {
      for (var topping in toppings) {
        if (topping is Map && topping.containsKey('price')) {
          totalPrice += _getNumericValue(topping['price']);
        }
      }
    }

    // Add addons price
    final addons = item['addons'];
    if (addons != null && addons is List) {
      for (var addon in addons) {
        if (addon is Map && addon.containsKey('price')) {
          totalPrice += _getNumericValue(addon['price']);
        }
      }
    }

    return totalPrice;
  }

  // Method untuk mendapatkan status pembayaran dengan dukungan down payment
  Map<String, dynamic> _getPaymentStatus(String? status, Map<String, dynamic>? paymentDetails) {
    // Check if this is a down payment scenario
    if (paymentDetails != null && paymentDetails['isDownPayment'] == true) {
      final isDownPaymentPaid = paymentDetails['downPaymentPaid'] == true;
      final remainingAmount = _getNumericValue(paymentDetails['remainingAmount']);

      if (isDownPaymentPaid && remainingAmount > 0) {
        return {
          'label': 'DP Dibayar - Sisa Belum Lunas',
          'icon': Icons.schedule,
          'color': Colors.deepOrange,
        };
      } else if (isDownPaymentPaid && remainingAmount == 0) {
        return {
          'label': 'Lunas',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      } else {
        return {
          'label': 'DP Belum Dibayar',
          'icon': Icons.pending,
          'color': Colors.red,
        };
      }
    }

    // Default payment status logic
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
      case 'partial':
        return {
          'label': 'Menunggu Pelunasan',
          'icon': Icons.remove_circle,
          'color': Colors.amber,
        };
      case 'pending':
        return {
          'label': 'Menunggu Pembayaran',
          'icon': Icons.access_time,
          'color': Colors.orange,
        };
      case 'expire':
      case 'unpaid':
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
      default:
        return {
          'label': 'Status Tidak Diketahui',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  // Widget untuk menampilkan informasi down payment
  Widget _buildDownPaymentSection(Map<String, dynamic> orderData) {
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    if (paymentDetails == null || paymentDetails['isDownPayment'] != true) {
      return const SizedBox.shrink();
    }

    final paidAmount = _getNumericValue(paymentDetails['paidAmount']);
    final remainingAmount = _getNumericValue(paymentDetails['remainingAmount']);
    final isDownPaymentPaid = paymentDetails['downPaymentPaid'] == true;

    return Column(
      children: [
        // Down Payment Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Informasi Down Payment',
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

        // DP Details Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // DP Amount with Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDownPaymentPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDownPaymentPaid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDownPaymentPaid ? Icons.check_circle : Icons.access_time,
                      size: 20,
                      color: isDownPaymentPaid ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Down Payment (DP)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            isDownPaymentPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDownPaymentPaid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(paidAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDownPaymentPaid ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Remaining Amount
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            remainingAmount > 0 ? 'Belum Lunas' : 'Lunas',
                            style: TextStyle(
                              fontSize: 12,
                              color: remainingAmount > 0 ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(remainingAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: remainingAmount > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 0),
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
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List? ?? [];
    final customAmountItems = orderData['customAmountItems'] as List? ?? []; // ✅ TAMBAH: ambil customAmountItems
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    // Safe access untuk paymentStatus dengan support down payment
    final paymentStatusValue = orderData['paymentStatus']?.toString();
    final paymentStatus = _getPaymentStatus(paymentStatusValue, paymentDetails);

    print('Payment Status Value: $paymentStatusValue');
    print('Payment Details: $paymentDetails');
    print('Custom Amount Items: $customAmountItems'); // ✅ Debug log

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
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E8B57),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B57).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          orderData['orderDate']?.toString() ?? 'No Date',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E8B57),
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
            if (items.isNotEmpty || customAmountItems.isNotEmpty) ...[
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
                            color: const Color(0xFF2E8B57).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF2E8B57),
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

                    // ✅ PERBAIKAN: Loop through regular items
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final itemTotalPrice = _calculateItemTotalPrice(item);
                      final quantity = _getNumericValue(item['quantity']);
                      final totalForItem = itemTotalPrice * quantity;

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B57).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
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
                                    'x${quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatCurrency(totalForItem),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
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
                            ],
                          ],
                        ),
                      );
                    }),

                    // ✅ TAMBAH: Loop through customAmountItems
                    ...customAmountItems.asMap().entries.map((entry) {
                      final customItem = entry.value;

                      final amount = _getNumericValue(customItem['amount']);
                      final name = customItem['name']?.toString() ?? 'Item Custom';
                      final description = customItem['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05), // Warna berbeda untuk custom item
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Badge "CUSTOM"
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'CUSTOM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatCurrency(amount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        description,
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
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Divider
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
              const SizedBox(height: 20),
            ],

            // Add Order Button (jika showAddOrderButton = true)
            if (showAddOrderButton && onAddOrder != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 24, right: 24, bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: onAddOrder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF2E8B57),
                  ),
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                  label: const Text(
                    'Tambah Pesanan',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            // Down Payment Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _buildDownPaymentSection(orderData),
            ),

            // Payment Detail Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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

                  // Subtotal
                  PaymentRowWidget(
                    label: 'Subtotal',
                    value: formatCurrency(_getNumericValue(orderData['totalBeforeDiscount'])),
                    icon: Icons.calculate,
                    isTotal: false,
                  ),

                  // Voucher discount
                  if (orderData['voucher'] != null) ...[
                    const SizedBox(height: 8),
                        () {
                      final voucher = orderData['voucher'] as Map<String, dynamic>;
                      final voucherCode = voucher['code']?.toString() ?? '';
                      final discountType = voucher['discountType']?.toString() ?? 'fixed';
                      final discountAmount = _getNumericValue(voucher['discountAmount']);

                      final totalBeforeDiscount = _getNumericValue(orderData['totalBeforeDiscount']);
                      final actualDiscount = discountType == 'percentage'
                          ? (totalBeforeDiscount * discountAmount / 100).round()
                          : discountAmount.round();

                      final labelText = discountType == 'percentage'
                          ? 'Kupon Diskon ($voucherCode ${discountAmount.toStringAsFixed(0)}%)'
                          : 'Kupon Diskon ($voucherCode)';

                      return PaymentRowWidget(
                        label: labelText,
                        value: '-${formatCurrency(actualDiscount)}',
                        icon: Icons.local_offer,
                        isTotal: false,
                      );
                    }(),
                    const SizedBox(height: 8),
                    PaymentRowWidget(
                      label: 'Subtotal setelah diskon',
                      value: formatCurrency(_getNumericValue(orderData['totalAfterDiscount'])),
                      icon: Icons.price_check,
                      isTotal: false,
                    ),
                  ],

                  // Tax details
                  if (orderData['taxAndServiceDetails'] != null) ...[
                    const SizedBox(height: 8),
                    ...(orderData['taxAndServiceDetails'] as List).map<Widget>((taxDetail) {
                      final taxAmount = _getNumericValue(taxDetail['amount']);
                      final taxName = taxDetail['name']?.toString() ?? '';
                      final totalAfterDiscount = _getNumericValue(orderData['totalAfterDiscount']);

                      double percentage = 0.0;
                      if (totalAfterDiscount > 0) {
                        percentage = (taxAmount / totalAfterDiscount) * 100;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PaymentRowWidget(
                          label: '$taxName (${percentage.toStringAsFixed(0)}%)',
                          value: formatCurrency(taxAmount),
                          icon: Icons.account_balance,
                          isTotal: false,
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 8),
                  PaymentRowWidget(
                    label: 'Total',
                    value: formatCurrency(_getNumericValue(orderData['grandTotal'])),
                    icon: Icons.receipt,
                    isTotal: true,
                  ),

                  if (paymentDetails?['isDownPayment'] != true || items.isNotEmpty || customAmountItems.isNotEmpty)
                    const SizedBox(height: 16),

                  PaymentRowWidget(
                    label: 'Metode Pembayaran',
                    value: orderData['paymentMethod']?.toString() ?? 'Not specified',
                    icon: Icons.credit_card,
                    isTotal: false,
                  ),
                  const SizedBox(height: 12),

                  // Payment Status
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
      ),
    );
  }

  // Helper methods
  num _getNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }
}