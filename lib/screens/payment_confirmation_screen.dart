import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/utils/classic_app_bar.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final List<CartItem> items;
  final OrderType orderType;
  final String tableNumber;
  final String deliveryAddress;
  final TimeOfDay? pickupTime;
  final String paymentMethod;
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;

  const PaymentConfirmationScreen({
    super.key,
    required this.items,
    required this.orderType,
    required this.tableNumber,
    required this.deliveryAddress,
    required this.pickupTime,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.voucherCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Konfirmasi Pembayaran'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Pembayaran
                  _buildSectionTitle('Informasi Pembayaran'),
                  _buildInfoItem('Metode Pembayaran', paymentMethod),
                  const SizedBox(height: 8),
                  _buildInfoItem('Total Pembayaran', formatCurrency(total)),

                  const Divider(height: 32),

                  // Informasi Order
                  _buildSectionTitle('Informasi Pesanan'),
                  _buildInfoItem('Tipe Pesanan', _getOrderTypeText()),

                  if (orderType == OrderType.dineIn && tableNumber.isNotEmpty)
                    _buildInfoItem('Nomor Meja', tableNumber),

                  if (orderType == OrderType.delivery && deliveryAddress.isNotEmpty)
                    _buildInfoItem('Alamat Pengantaran', deliveryAddress),

                  if (orderType == OrderType.pickup && pickupTime != null)
                    _buildInfoItem('Waktu Pengambilan',
                        '${pickupTime!.hour}:${pickupTime!.minute.toString().padLeft(2, '0')}'),

                  const Divider(height: 32),

                  // Detail Pesanan
                  _buildSectionTitle('Detail Pesanan'),
                  ...items.map((item) => _buildOrderItem(item)),

                  const Divider(height: 32),

                  // Rincian Biaya
                  _buildSectionTitle('Rincian Biaya'),
                  _buildInfoItem('Subtotal', formatCurrency(subtotal)),
                  if (discount > 0) ...[
                    _buildInfoItem('Diskon', '- ${formatCurrency(discount)}'),
                    if (voucherCode != null && voucherCode!.isNotEmpty)
                      _buildInfoItem('Voucher', voucherCode!),
                  ],
                  const Divider(height: 16),
                  _buildInfoItem('Total', formatCurrency(total), isBold: true),
                ],
              ),
            ),
          ),

          // Button Konfirmasi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _confirmPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Konfirmasi Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget for info items
  Widget _buildInfoItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for order items
  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item quantity
          Text(
            '${item.quantity}x',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.additional != '-')
                  Text(
                    'Additional: ${item.additional}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if (item.topping != '-')
                  Text(
                    'Topping: ${item.topping}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Item price
          Text(
            formatCurrency(item.price * item.quantity),
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get order type text
  String _getOrderTypeText() {
    switch (orderType) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.delivery:
        return 'Pengantaran';
      case OrderType.pickup:
        return 'Ambil Sendiri';
    }
  }

  // Confirm payment and create order
  void _confirmPayment(BuildContext context) {
    // Generate a unique order ID (using timestamp)
    final String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Create a new order with new instances of CartItem
    final Order newOrder = Order(
      id: orderId,
      items: items.map((item) => CartItem(
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        additional: item.additional,
        topping: item.topping,
        // Include any other necessary fields from CartItem
        imageUrl: item.imageUrl, // Assuming there's an imageUrl field
      )).toList(),
      orderType: orderType,
      tableNumber: tableNumber,
      deliveryAddress: deliveryAddress,
      pickupTime: pickupTime,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discount: discount,
      total: total,
      voucherCode: voucherCode,
      orderTime: DateTime.now(),
      status: OrderStatus.processing, // Payment confirmed, order is now processing
    );

    // Save order to provider
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.addOrder(newOrder);

    // Navigate to order success screen
    context.go('/orderSuccess?id=$orderId');
  }
}