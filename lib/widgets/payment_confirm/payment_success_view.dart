// import 'package:flutter/material.dart';
// import 'package:baraja_app/theme/app_theme.dart';
// import 'package:go_router/go_router.dart';
// import '../../models/cart_item.dart';
// import '../../models/order.dart';
// import '../../models/order_type.dart';
// import '../../utils/currency_formatter.dart';
// import 'payment_status_card.dart';
// import 'payment_instructions.dart';
//
// class PaymentSuccessView extends StatelessWidget {
//   final Order order;
//   final Map<String, dynamic>? paymentResponse;
//   final Map<String, String?> paymentDetails;
//   final OrderType orderType;
//   final String tableNumber;
//   final String deliveryAddress;
//   final TimeOfDay? pickupTime;
//   final int subtotal;
//   final int discount;
//   final int total;
//   final String? voucherCode;
//   final List<CartItem> items;
//
//   const PaymentSuccessView({
//     super.key,
//     required this.order,
//     required this.paymentResponse,
//     required this.paymentDetails,
//     required this.orderType,
//     required this.tableNumber,
//     required this.deliveryAddress,
//     required this.pickupTime,
//     required this.subtotal,
//     required this.discount,
//     required this.total,
//     required this.voucherCode,
//     required this.items,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 PaymentStatusCard(paymentResponse: paymentResponse, orderId: order.orderId),
//                 const SizedBox(height: 24),
//
//                 _buildSectionTitle('Informasi Pembayaran'),
//                 _buildInfoItem('Metode Pembayaran', paymentDetails['bankName'] ?? 'Unknown'),
//                 const SizedBox(height: 8),
//                 _buildInfoItem('Total Pembayaran', formatCurrency(total)),
//
//                 if (paymentResponse != null) ...[
//                   const SizedBox(height: 8),
//                   PaymentInstructions(paymentResponse: paymentResponse!),
//                 ],
//
//                 const Divider(height: 32),
//                 _buildSectionTitle('Informasi Pesanan'),
//                 _buildInfoItem('Tipe Pesanan', _getOrderTypeText(orderType)),
//
//                 if (orderType == OrderType.dineIn && tableNumber.isNotEmpty)
//                   _buildInfoItem('Nomor Meja', tableNumber),
//                 if (orderType == OrderType.delivery && deliveryAddress.isNotEmpty)
//                   _buildInfoItem('Alamat Pengantaran', deliveryAddress),
//                 if (orderType == OrderType.pickup && pickupTime != null)
//                   _buildInfoItem('Waktu Pengambilan',
//                       '${pickupTime!.hour}:${pickupTime!.minute.toString().padLeft(2, '0')}'),
//
//                 const Divider(height: 32),
//                 _buildSectionTitle('Detail Pesanan'),
//                 ...items.map((item) => _buildOrderItem(item)),
//
//                 const Divider(height: 32),
//                 _buildSectionTitle('Rincian Biaya'),
//                 _buildInfoItem('Subtotal', formatCurrency(subtotal)),
//                 if (discount > 0) ...[
//                   _buildInfoItem('Diskon', '- ${formatCurrency(discount)}'),
//                   if (voucherCode != null && voucherCode!.isNotEmpty)
//                     _buildInfoItem('Voucher', voucherCode!),
//                 ],
//                 const Divider(height: 16),
//                 _buildInfoItem('Total', formatCurrency(total), isBold: true),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: ElevatedButton(
//             onPressed: () {
//               // Ganti 'yourOrderId' dengan variabel orderId sebenarnya
//
//               context.go('/orderDetail', extra: order.id);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.primaryColor,
//               foregroundColor: Colors.white,
//               minimumSize: const Size.fromHeight(50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text(
//               'Lihat Pesanan Saya',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//         )
//       ],
//     );
//   }
//   String _getOrderTypeText(OrderType type) {
//     switch (type) {
//       case OrderType.dineIn:
//         return 'Makan di Tempat';
//       case OrderType.delivery:
//         return 'Pengantaran';
//       case OrderType.pickup:
//         return 'Ambil Sendiri';
//       case OrderType.reservation:
//         return 'Reservasi';
//     }
//   }
//
//
//   Widget _buildOrderItem(CartItem item) => Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('${item.quantity}x', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//               const SizedBox(width: 12),
//               // Tambahan (Addons) Section
//               if (item.addons.isNotEmpty) ...[
//                 const Row(
//                   children: [
//                     Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
//                     SizedBox(width: 4),
//                     Text(
//                       'Tambahan:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   margin: const EdgeInsets.only(left: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: item.addons.map((addon) => Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 2.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.circle, size: 6, color: Colors.blue),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     '${addon["name"]}: ${addon["label"]}',
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Text(
//                             formatCurrency(addon["price"]),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )).toList(),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//               const SizedBox(width: 12),
//               // Topping Section
//               if ((item.toppings is String && (item.toppings as String).isNotEmpty) ||
//                   ((item.toppings as List).isNotEmpty)) ...[
//                 const Row(
//                   children: [
//                     Icon(Icons.cake, size: 16, color: Colors.deepOrange),
//                     SizedBox(width: 4),
//                     Text(
//                       'Topping:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   margin: const EdgeInsets.only(left: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.deepOrange.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
//                   ),
//                   child: item.toppings is List<Map<String, Object>>
//                       ? Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: (item.toppings as List<Map<String, Object>>).map((topping) => Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 2.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     '${topping["name"]}',
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (topping.containsKey("price") && topping["price"] != null)
//                             Text(
//                               formatCurrency(topping["price"] as num),
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.deepOrange,
//                               ),
//                             ),
//                         ],
//                       ),
//                     )).toList(),
//                   )
//                       : Row(
//                     children: [
//                       const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           item.toppings is String
//                               ? item.toppings as String
//                           // ignore: unnecessary_type_check
//                               : item.toppings is List
//                               ? (item.toppings as List).join(', ')
//                               : '',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//
//               // Notes Section
//               if (item.notes != null && item.notes!.isNotEmpty) ...[
//                 const Row(
//                   children: [
//                     Icon(Icons.note_outlined, size: 16, color: Colors.amber),
//                     SizedBox(width: 4),
//                     Text(
//                       'Catatan:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(8),
//                   margin: const EdgeInsets.only(left: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.amber.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.amber.withOpacity(0.3)),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Icon(Icons.format_quote, size: 14, color: Colors.amber),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           item.notes!,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontStyle: FontStyle.italic,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ],
//           ),
//         ),
//         Text(formatCurrency(item.price * item.quantity), style: const TextStyle(fontSize: 14)),
//       ],
//     ),
//   );
//
//   Widget _buildSectionTitle(String title) => Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//   );
//
//   Widget _buildInfoItem(String label, String value, {bool isBold = false}) => Padding(
//     padding: const EdgeInsets.only(bottom: 8),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//         Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
//       ],
//     ),
//   );
// }
//
