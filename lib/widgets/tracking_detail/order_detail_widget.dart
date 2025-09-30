import 'package:flutter/material.dart';
import '../../models/reservation_data.dart';
import '../../screens/menu_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'payment_row_widget.dart';

class OrderDetailWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailWidget({
    super.key,
    required this.orderData,
  });

//   Widget _buildVoucherSection(Map<String, dynamic> orderData) {
//     final voucher = orderData['voucher'] as Map<String, dynamic>?;
//
//     if (voucher == null) {
//       return const SizedBox.shrink();
//     }
//
//     final discountAmount = _getNumericValue(voucher['discountAmount']);
//     final voucherCode = voucher['code']?.toString() ?? '';
//     final voucherName = voucher['name']?.toString() ?? '';
//
//     return Column(
//       children: [
//         // Voucher Section Header
//         Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.local_offer,
//                 color: Colors.green,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               'Voucher Diskon',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//                 letterSpacing: -0.5,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//
//         // Voucher Details Container
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.green.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.green.withOpacity(0.2),
//             ),
//           ),
//           child: Column(
//             children: [
//               // Voucher Code
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.confirmation_number,
//                       size: 20,
//                       color: Colors.green,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Kode Voucher',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             voucherCode,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//
//               // Voucher Name and Discount
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.discount,
//                       size: 20,
//                       color: Colors.green,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             voucherName,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade700,
//                             ),
//                           ),
//                           Text(
//                             'Diskon Diterapkan',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade500,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '-${formatCurrency(discountAmount)}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 20),
//
//         // Divider
//         Container(
//           height: 1,
//           margin: const EdgeInsets.symmetric(horizontal: 0),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.transparent,
//                 Colors.grey.shade200,
//                 Colors.transparent,
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
// // Widget untuk menampilkan informasi tax
//   Widget _buildTaxSection(Map<String, dynamic> orderData) {
//     final taxAndServiceDetails = orderData['taxAndServiceDetails'] as List?;
//     final totalBeforeDiscount = _getNumericValue(orderData['totalBeforeDiscount']);
//     final totalAfterDiscount = _getNumericValue(orderData['totalAfterDiscount']);
//
//     if (taxAndServiceDetails == null || taxAndServiceDetails.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     return Column(
//       children: [
//         // Tax Section Header
//         Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.receipt_long,
//                 color: Colors.blue,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               'Pajak & Biaya Layanan',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black87,
//                 letterSpacing: -0.5,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//
//         // Tax Details Container
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.blue.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.blue.withOpacity(0.2),
//             ),
//           ),
//           child: Column(
//             children: taxAndServiceDetails.map<Widget>((taxDetail) {
//               final taxName = taxDetail['name']?.toString() ?? '';
//               final taxAmount = _getNumericValue(taxDetail['amount']);
//               final taxType = taxDetail['type']?.toString() ?? '';
//
//               // Calculate percentage based on total after discount (before tax)
//               double percentage = 0.0;
//               if (totalAfterDiscount > 0) {
//                 percentage = (taxAmount / totalAfterDiscount) * 100;
//               }
//
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Colors.blue.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       taxType == 'tax' ? Icons.account_balance : Icons.room_service,
//                       size: 20,
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             taxName,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade700,
//                             ),
//                           ),
//                           Text(
//                             '${percentage.toStringAsFixed(1)}%',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade500,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       formatCurrency(taxAmount),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         const SizedBox(height: 20),
//
//         // Divider
//         Container(
//           height: 1,
//           margin: const EdgeInsets.symmetric(horizontal: 0),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.transparent,
//                 Colors.grey.shade200,
//                 Colors.transparent,
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

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

    // Default payment status logic (existing code)
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
      case 'Paid':
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
      case 'Unpaid':
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

  // Widget untuk menampilkan informasi down payment
  Widget _buildDownPaymentSection(Map<String, dynamic> orderData) {
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    if (paymentDetails == null || paymentDetails['isDownPayment'] != true) {
      return const SizedBox.shrink();
    }

    // final totalAmount = _getNumericValue(paymentDetails['totalAmount']);
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
              // Total Amount (hanya tampilkan jika > 0)
              // if (totalAmount > 0) ...[
              //   _buildPaymentDetailRow(
              //     'Total Pesanan',
              //     formatCurrency(totalAmount),
              //     Icons.receipt_long,
              //     Colors.grey.shade700,
              //   ),
              //   const SizedBox(height: 8),
              // ],

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

  // Widget _buildPaymentDetailRow(String label, String value, IconData icon, Color iconColor) {
  //   return Row(
  //     children: [
  //       Icon(
  //         icon,
  //         size: 18,
  //         color: iconColor,
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.grey.shade700,
  //           ),
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w700,
  //           color: Colors.black87,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List? ?? [];
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    // Safe access untuk paymentStatus dengan support down payment
    final paymentStatusValue = orderData['paymentStatus']?.toString();
    final paymentStatus = _getPaymentStatus(paymentStatusValue, paymentDetails);

    print('Payment Status Value: $paymentStatusValue');
    print('Payment Details: $paymentDetails');

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

          // Order Detail Section (only show if items exist)
          if (items.isNotEmpty) ...[
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

                          const SizedBox(height: 12),
                          Text(
                            item['outletName']?.toString() ?? 'Unknown Outlet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
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
            const SizedBox(height: 20),
          ],

          // Add Order Button for reservations
          if (orderData['reservation'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 24, right: 24, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  final reservationId = orderData['reservation']?['_id']?.toString() ?? '';
                  final selectedArea = orderData['reservation']?['area'];
                  final selectedTable = orderData['reservation']?['tables'] as List?;

                  final areaId = selectedArea?['_id']?.toString() ?? '';
                  final areaCode = selectedArea?['name']?.toString() ?? '';

                  final tableId = (selectedTable != null && selectedTable.isNotEmpty)
                      ? selectedTable[0]['_id']?.toString() ?? ''
                      : '';
                  final tableNumbers = (selectedTable != null && selectedTable.isNotEmpty)
                      ? selectedTable[0]['tableNumber']?.toString() ?? ''
                      : '';

                  final openBillData = OpenBillData(
                    reservationId: reservationId,
                    date: DateTime.now(),
                    time: TimeOfDay.now(),
                    areaId: areaId,
                    areaCode: areaCode,
                    tableId: tableId,
                    tableNumbers: tableNumbers,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuScreen(
                        isOpenBill: true,
                        openBillData: openBillData,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                ),
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                label: const Text(
                  'Tambah Pesanan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          // Down Payment Section (NEW)
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

                // Subtotal (before discount)
                PaymentRowWidget(
                  label: 'Subtotal',
                  value: formatCurrency(_getNumericValue(orderData['totalBeforeDiscount'])),
                  icon: Icons.calculate,
                  isTotal: false,
                ),

                // Show voucher discount if exists
                // Show voucher discount if exists
                if (orderData['voucher'] != null) ...[
                  const SizedBox(height: 8),
                      () {
                    final voucher = orderData['voucher'] as Map<String, dynamic>;
                    final voucherCode = voucher['code']?.toString() ?? '';
                    final discountType = voucher['discountType']?.toString() ?? 'fixed';
                    final discountAmount = _getNumericValue(voucher['discountAmount']);

                    // Calculate actual discount in rupiah
                    final totalBeforeDiscount = _getNumericValue(orderData['totalBeforeDiscount']);
                    final actualDiscount = discountType == 'percentage'
                        ? (totalBeforeDiscount * discountAmount / 100).round()
                        : discountAmount.round();

                    final labelText = discountType == 'percentage'
                        ? 'Kupon Diskon ($voucherCode${discountAmount.toStringAsFixed(0)}%)'
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

                // Show tax details
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

                if (paymentDetails?['isDownPayment'] != true || items.isNotEmpty)
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
          )
        ],
      ),
    );
  }

  // Helper methods remain the same...

  Widget _buildItemImage(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl']?.toString();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white, // ✅ selalu putih
      child: (imageUrl != null &&
          imageUrl.isNotEmpty &&
          imageUrl != 'https://placehold.co/1920x1080/png')
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/product_default_image.png',
            fit: BoxFit.cover,
          );
        },
      )
          : Image.asset(
        'assets/images/product_default_image.png',
        fit: BoxFit.cover,
      ),
    );
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